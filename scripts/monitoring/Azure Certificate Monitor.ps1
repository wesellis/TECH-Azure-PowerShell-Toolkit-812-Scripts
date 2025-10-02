#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    Azure Certificate Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [int]$ExpirationWarningDays = 30,
    [Parameter()]
    [switch]$CheckKeyVaultCertificates,
    [Parameter()]
    [switch]$CheckAppGatewayCertificates
)
Write-Output "Azure Script Started" # Color: $2 "Azure Certificate Monitor" -Version " 1.0" -Description "Monitor SSL certificate expiration"
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    [string]$ExpiringCertificates = @()
    [string]$WarningDate = (Get-Date).AddDays($ExpirationWarningDays)
    if ($CheckKeyVaultCertificates) {
    [string]$KeyVaults = Get-AzKeyVault -ErrorAction Stop
        foreach ($vault in $KeyVaults) {
            try {
    [string]$certificates = Get-AzKeyVaultCertificate -VaultName $vault.VaultName
                foreach ($cert in $certificates) {
    [string]$CertDetails = Get-AzKeyVaultCertificate -VaultName $vault.VaultName -Name $cert.Name
                    if ($CertDetails.Expires -and $CertDetails.Expires -le $WarningDate) {
    [string]$ExpiringCertificates = $ExpiringCertificates + [PSCustomObject]@{
                            Service = "Key Vault"
                            VaultName = $vault.VaultName
                            CertificateName = $cert.Name
                            ExpirationDate = $CertDetails.Expires
                            DaysUntilExpiration = [math]::Round(($CertDetails.Expires - (Get-Date)).TotalDays)
                        }
                    }
                }
            } catch {

            }
        }
    }
    Write-Output "Certificate Monitoring Results:" # Color: $2
    Write-Output "Warning threshold: $ExpirationWarningDays days" # Color: $2
    Write-Output "Certificates expiring soon: $($ExpiringCertificates.Count)" # Color: $2
    if ($ExpiringCertificates.Count -gt 0) {
    [string]$ExpiringCertificates | Sort-Object ExpirationDate | Format-Table Service, VaultName, CertificateName, ExpirationDate, DaysUntilExpiration
    } else {
        Write-Output "No certificates expiring within $ExpirationWarningDays days" # Color: $2
    }
} catch {

    throw`n}
