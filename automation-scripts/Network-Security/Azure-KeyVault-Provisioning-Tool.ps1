# ============================================================================
# Script Name: Azure Key Vault Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Key Vault with security configurations and access policies
# ============================================================================

param (
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
$KeyVault = New-AzKeyVault `
    -ResourceGroupName $ResourceGroupName `
    -VaultName $VaultName `
    -Location $Location `
    -Sku $SkuName `
    -EnabledForDeployment:$EnabledForDeployment `
    -EnabledForTemplateDeployment:$EnabledForTemplateDeployment `
    -EnabledForDiskEncryption:$EnabledForDiskEncryption

Write-Host "Key Vault $VaultName provisioned successfully"
Write-Host "Vault URI: $($KeyVault.VaultUri)"
Write-Host "Enabled for Deployment: $EnabledForDeployment"
Write-Host "Enabled for Template Deployment: $EnabledForTemplateDeployment"
Write-Host "Enabled for Disk Encryption: $EnabledForDiskEncryption"
