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

    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [bool]$EnabledForDeployment = $true,
    [bool]$EnabledForTemplateDeployment = $true,
    [bool]$EnabledForDiskEncryption = $true
)
Write-Output "Provisioning Key Vault: $VaultName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $SkuName"
$params = @{
    Sku = $SkuName
    VaultName = $VaultName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$KeyVault = New-AzKeyVault @params
Write-Output "Key Vault $VaultName provisioned successfully"
Write-Output "Vault URI: $($KeyVault.VaultUri)"
Write-Output "Enabled for Deployment: $EnabledForDeployment"
Write-Output "Enabled for Template Deployment: $EnabledForTemplateDeployment"
Write-Output "Enabled for Disk Encryption: $EnabledForDiskEncryption"



