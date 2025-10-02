#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    Manage Key Vault

.DESCRIPTION
    Manage Key Vault
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$VaultName,
    [Parameter(Mandatory)]
    [string]$SecretName,
    [Parameter()]
    [switch]$AsPlainText
)
Write-Output "Retrieving secret from Key Vault: $VaultName"
$Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
if ($AsPlainText) {
    $SecretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret.SecretValue))
    Write-Output "Secret Value: $SecretValue"
} else {
    Write-Output "Secret retrieved (use -AsPlainText to display value):"
}
Write-Output "Name: $($Secret.Name)"
Write-Output "Version: $($Secret.Version)"
Write-Output "Created: $($Secret.Created)"
Write-Output "Updated: $($Secret.Updated)"



