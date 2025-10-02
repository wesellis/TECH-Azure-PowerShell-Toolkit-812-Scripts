#Requires -Version 7.4
#Requires -Modules Az.KeyVault, Az.Accounts

<#
.SYNOPSIS
    Deploys an Azure Key Vault with a software-based key

.DESCRIPTION
    This script creates a new Azure Key Vault in the specified resource group and location,
    then adds a software-based key to the vault. It uses the modern Az PowerShell modules.

.PARAMETER SubscriptionId
    The Azure subscription ID where the Key Vault will be created

.PARAMETER ResourceGroupName
    The name of the resource group where the Key Vault will be created

.PARAMETER KeyVaultLocation
    The Azure region where the Key Vault will be deployed

.PARAMETER KeyVaultName
    The name of the Key Vault to create

.PARAMETER KeyName
    The name of the key to add to the Key Vault

.EXAMPLE
    .\Deploy-Vault.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "MyRG" -KeyVaultLocation "East US" -KeyVaultName "MyVault" -KeyName "MyKey"

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyVaultLocation,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyVaultName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyName
)

$ErrorActionPreference = "Stop"

try {
    Connect-AzAccount
    Write-Information "Selecting Azure Subscription: $SubscriptionId" -InformationAction Continue
    Set-AzContext -SubscriptionId $SubscriptionId

    Write-Information "Creating the new Key Vault: $KeyVaultName" -InformationAction Continue
    New-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $KeyVaultLocation -EnableSoftDelete

    Write-Information "Adding the new key inside the Key Vault: $KeyName" -InformationAction Continue
    Add-AzKeyVaultKey -VaultName $KeyVaultName -Name $KeyName -Destination 'Software'

    Write-Information "Key Vault deployment completed successfully" -InformationAction Continue
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
