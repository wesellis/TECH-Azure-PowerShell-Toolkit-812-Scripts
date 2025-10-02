#Requires -Version 7.4
#Requires -Modules Az.KeyVault
#Requires -Modules Az.Resources
#Requires -Module Az.Resources
<#`n.SYNOPSIS
    Check certificate expiry

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Check certificate expiration in Key Vaults
.PARAMETER Vault
Key Vault name to check
.PARAMETER Days
Days until expiration to warn (default 30)
.\Get-CertExpiry.ps1 -Vault myvault
.\Get-CertExpiry.ps1 -Days 60
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
`n}
