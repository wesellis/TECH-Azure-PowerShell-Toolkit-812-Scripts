#Requires -Version 7.0
#Requires -Modules Az.KeyVault

<#
.SYNOPSIS
    Manage Key Vault

.DESCRIPTION
    Manage Key Vault
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [bool]$EnabledForDeployment = $true,
    [bool]$EnabledForTemplateDeployment = $true,
    [bool]$EnabledForDiskEncryption = $true
)
Write-Host "Provisioning Key Vault: $VaultName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName"
# Create the Key Vault
$params = @{
    Sku = $SkuName
    VaultName = $VaultName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$KeyVault = New-AzKeyVault @params
Write-Host "Key Vault $VaultName provisioned successfully"
Write-Host "Vault URI: $($KeyVault.VaultUri)"
Write-Host "Enabled for Deployment: $EnabledForDeployment"
Write-Host "Enabled for Template Deployment: $EnabledForTemplateDeployment"
Write-Host "Enabled for Disk Encryption: $EnabledForDiskEncryption"

