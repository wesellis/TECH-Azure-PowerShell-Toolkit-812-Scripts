#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Certificate Monitor
# Monitor SSL certificate expiration across Azure services
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [int]$ExpirationWarningDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckKeyVaultCertificates,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckAppGatewayCertificates
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName "Azure Certificate Monitor" -Version "1.0" -Description "Monitor SSL certificate expiration"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

    $expiringCertificates = @()
    $warningDate = (Get-Date).AddDays($ExpirationWarningDays)

    if ($CheckKeyVaultCertificates) {
        $keyVaults = Get-AzKeyVault -ErrorAction Stop
        
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
                Write-Log "[WARN]️ Could not access certificates in vault: $($vault.VaultName)" -Level WARNING
            }
        }
    }

    Write-Information "Certificate Monitoring Results:"
    Write-Information "Warning threshold: $ExpirationWarningDays days"
    Write-Information "Certificates expiring soon: $($expiringCertificates.Count)"

    if ($expiringCertificates.Count -gt 0) {
        $expiringCertificates | Sort-Object ExpirationDate | Format-Table Service, VaultName, CertificateName, ExpirationDate, DaysUntilExpiration
    } else {
        Write-Information " No certificates expiring within $ExpirationWarningDays days"
    }

} catch {
    Write-Log " Certificate monitoring failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


#endregion
