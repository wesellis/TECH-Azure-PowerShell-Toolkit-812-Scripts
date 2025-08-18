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

Write-Information "Provisioning Storage Account: $StorageAccountName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName"
Write-Information "Kind: $Kind"
Write-Information "Access Tier: $AccessTier"

# Create the storage account
$StorageAccount = New-AzStorageAccount -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -Location $Location `
    -SkuName $SkuName `
    -Kind $Kind `
    -AccessTier $AccessTier `
    -EnableHttpsTrafficOnly $true

Write-Information "Storage Account $StorageAccountName provisioned successfully"
Write-Information "Primary Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)"
