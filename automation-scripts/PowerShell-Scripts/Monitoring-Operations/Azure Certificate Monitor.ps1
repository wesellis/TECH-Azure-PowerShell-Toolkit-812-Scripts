#Requires -Version 7.0
#Requires -Modules Az.KeyVault

<#
.SYNOPSIS
    Azure Certificate Monitor

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [int]$ExpirationWarningDays = 30,
    [Parameter()]
    [switch]$CheckKeyVaultCertificates,
    [Parameter()]
    [switch]$CheckAppGatewayCertificates
)
Write-Host "Azure Script Started" -ForegroundColor GreenName "Azure Certificate Monitor" -Version " 1.0" -Description "Monitor SSL certificate expiration"
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
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
$expiringCertificates = $expiringCertificates + [PSCustomObject]@{
                            Service = "Key Vault"
                            VaultName = $vault.VaultName
                            CertificateName = $cert.Name
                            ExpirationDate = $certDetails.Expires
                            DaysUntilExpiration = [math]::Round(($certDetails.Expires - (Get-Date)).TotalDays)
                        }
                    }
                }
            } catch {

            }
        }
    }
    Write-Host "Certificate Monitoring Results:" -ForegroundColor Cyan
    Write-Host "Warning threshold: $ExpirationWarningDays days" -ForegroundColor Yellow
    Write-Host "Certificates expiring soon: $($expiringCertificates.Count)" -ForegroundColor Red
    if ($expiringCertificates.Count -gt 0) {
        $expiringCertificates | Sort-Object ExpirationDate | Format-Table Service, VaultName, CertificateName, ExpirationDate, DaysUntilExpiration
    } else {
        Write-Host "No certificates expiring within $ExpirationWarningDays days" -ForegroundColor Green
    }
} catch {

    throw
}\n

