#Requires -Version 7.0
#Requires -Module Az.Resources
<#
.SYNOPSIS
    Check certificate expiry

.DESCRIPTION
    Check certificate expiration in Key Vaults
.PARAMETER Vault
Key Vault name to check
.PARAMETER Days
Days until expiration to warn (default 30)
.\Get-CertExpiry.ps1 -Vault myvault
.\Get-CertExpiry.ps1 -Days 60
#>
param(
    [string]$Vault,
    [int]$Days = 30
)
$vaults = if ($Vault) { Get-AzKeyVault -VaultName $Vault } else { Get-AzKeyVault }
$cutoff = (Get-Date).AddDays($Days)
foreach ($kv in $vaults) {
    $certs = Get-AzKeyVaultCertificate -VaultName $kv.VaultName -ErrorAction SilentlyContinue
    foreach ($cert in $certs) {
        $details = Get-AzKeyVaultCertificate -VaultName $kv.VaultName -Name $cert.Name
        if ($details.Expires -and $details.Expires -le $cutoff) {
            [PSCustomObject]@{
                Vault = $kv.VaultName
                Certificate = $cert.Name
                Expires = $details.Expires
                DaysLeft = [math]::Round(($details.Expires - (Get-Date)).TotalDays)
            }
        }
    }
}

