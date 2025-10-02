#Requires -Version 7.4
#Requires -Modules Az.Resources

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
    [Parameter(Mandatory)]
    [string]$SecretValue
)
Write-Output "Adding secret to Key Vault: $VaultName"
$SecureString = Read-Host -Prompt "Enter secure value" -AsSecureString
$Secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureString
Write-Output "Secret added successfully:"
Write-Output "Name: $($Secret.Name)"
Write-Output "Version: $($Secret.Version)"
Write-Output "Vault: $VaultName"
Write-Output "Created: $($Secret.Created)"



