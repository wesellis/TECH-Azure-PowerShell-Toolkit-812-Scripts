#Requires -Version 7.0
#Requires -Modules Az.KeyVault

<#
.SYNOPSIS
    Manage Key Vault

.DESCRIPTION
    Manage Key Vault
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$VaultName,
    [Parameter(Mandatory)]
    [string]$SecretName,
    [Parameter()]
    [switch]$AsPlainText
)
Write-Host "Retrieving secret from Key Vault: $VaultName"
$Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
if ($AsPlainText) {
    $SecretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret.SecretValue))
    Write-Host "Secret Value: $SecretValue"
} else {
    Write-Host "Secret retrieved (use -AsPlainText to display value):"
}
Write-Host "Name: $($Secret.Name)"
Write-Host "Version: $($Secret.Version)"
Write-Host "Created: $($Secret.Created)"
Write-Host "Updated: $($Secret.Updated)"

