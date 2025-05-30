# ============================================================================
# Script Name: Azure Storage Account Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions new Azure Storage Accounts with specified configurations
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$Location,
    [string]$SkuName = "Standard_LRS",
    [string]$Kind = "StorageV2",
    [string]$AccessTier = "Hot"
)

Write-Host "Provisioning Storage Account: $StorageAccountName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName"
Write-Host "Kind: $Kind"
Write-Host "Access Tier: $AccessTier"

# Create the storage account
$StorageAccount = New-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -Location $Location `
    -SkuName $SkuName `
    -Kind $Kind `
    -AccessTier $AccessTier `
    -EnableHttpsTrafficOnly $true

Write-Host "Storage Account $StorageAccountName provisioned successfully"
Write-Host "Primary Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)"
