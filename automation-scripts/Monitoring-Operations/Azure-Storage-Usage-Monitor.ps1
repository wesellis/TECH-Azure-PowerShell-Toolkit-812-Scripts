# ============================================================================
# Script Name: Azure Storage Account Usage and Capacity Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Storage Account usage, capacity, and performance metrics
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$StorageAccountName
)

# Get storage account details
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

# Get storage metrics
$Context = $StorageAccount.Context
$Usage = Get-AzStorageUsage -Context $Context

Write-Host "Storage Account: $($StorageAccount.StorageAccountName)"
Write-Host "Resource Group: $($StorageAccount.ResourceGroupName)"
Write-Host "Location: $($StorageAccount.Location)"
Write-Host "SKU: $($StorageAccount.Sku.Name)"
Write-Host "Usage: $($Usage.CurrentValue) / $($Usage.Limit)"
