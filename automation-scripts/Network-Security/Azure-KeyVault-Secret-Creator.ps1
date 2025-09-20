<#
.SYNOPSIS
    Manage Key Vault

.DESCRIPTION
    Manage Key Vault
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [Parameter(Mandatory)]
    [string]$VaultName,
    [Parameter(Mandatory)]
    [string]$SecretName,
    [Parameter(Mandatory)]
    [string]$SecretValue
)
Write-Host "Adding secret to Key Vault: $VaultName"
$SecureString = ConvertTo-SecureString $SecretValue -AsPlainText -Force
$Secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureString
Write-Host "Secret added successfully:"
Write-Host "Name: $($Secret.Name)"
Write-Host "Version: $($Secret.Version)"
Write-Host "Vault: $VaultName"
Write-Host "Created: $($Secret.Created)"

