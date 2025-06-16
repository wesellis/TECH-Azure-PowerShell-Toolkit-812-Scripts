# Azure Certificate Monitor
# Monitor SSL certificate expiration across Azure services
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [int]$ExpirationWarningDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckKeyVaultCertificates,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckAppGatewayCertificates
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Certificate Monitor" -Version "1.0" -Description "Monitor SSL certificate expiration"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

    $expiringCertificates = @()
    $warningDate = (Get-Date).AddDays($ExpirationWarningDays)

    if ($CheckKeyVaultCertificates) {
        $keyVaults = Get-AzKeyVault
        
        foreach ($vault in $keyVaults) {
            try {
                $certificates = Get-AzKeyVaultCertificate -VaultName $vault.VaultName
                
                foreach ($cert in $certificates) {
                    $certDetails = Get-AzKeyVaultCertificate -VaultName $vault.VaultName -Name $cert.Name
                    
                    if ($certDetails.Expires -and $certDetails.Expires -le $warningDate) {
                        $expiringCertificates += [PSCustomObject]@{
                            Service = "Key Vault"
                            VaultName = $vault.VaultName
                            CertificateName = $cert.Name
                            ExpirationDate = $certDetails.Expires
                            DaysUntilExpiration = [math]::Round(($certDetails.Expires - (Get-Date)).TotalDays)
                        }
                    }
                }
            } catch {
                Write-Log "⚠️ Could not access certificates in vault: $($vault.VaultName)" -Level WARNING
            }
        }
    }

    Write-Host "Certificate Monitoring Results:" -ForegroundColor Cyan
    Write-Host "Warning threshold: $ExpirationWarningDays days" -ForegroundColor Yellow
    Write-Host "Certificates expiring soon: $($expiringCertificates.Count)" -ForegroundColor Red

    if ($expiringCertificates.Count -gt 0) {
        $expiringCertificates | Sort-Object ExpirationDate | Format-Table Service, VaultName, CertificateName, ExpirationDate, DaysUntilExpiration
    } else {
        Write-Host "✅ No certificates expiring within $ExpirationWarningDays days" -ForegroundColor Green
    }

} catch {
    Write-Log "❌ Certificate monitoring failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
