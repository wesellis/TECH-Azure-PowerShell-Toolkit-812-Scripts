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

Write-Information "Provisioning Key Vault: $VaultName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName"

# Create the Key Vault
$KeyVault = New-AzKeyVault -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -VaultName $VaultName `
    -Location $Location `
    -Sku $SkuName `
    -EnabledForDeployment:$EnabledForDeployment `
    -EnabledForTemplateDeployment:$EnabledForTemplateDeployment `
    -EnabledForDiskEncryption:$EnabledForDiskEncryption

Write-Information "Key Vault $VaultName provisioned successfully"
Write-Information "Vault URI: $($KeyVault.VaultUri)"
Write-Information "Enabled for Deployment: $EnabledForDeployment"
Write-Information "Enabled for Template Deployment: $EnabledForTemplateDeployment"
Write-Information "Enabled for Disk Encryption: $EnabledForDiskEncryption"
