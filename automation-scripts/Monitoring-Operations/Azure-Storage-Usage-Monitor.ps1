#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$StorageAccountName
)

#region Functions

# Get storage account details
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

# Get storage metrics
$Context = $StorageAccount.Context
$Usage = Get-AzStorageUsage -Context $Context

Write-Information "Storage Account: $($StorageAccount.StorageAccountName)"
Write-Information "Resource Group: $($StorageAccount.ResourceGroupName)"
Write-Information "Location: $($StorageAccount.Location)"
Write-Information "SKU: $($StorageAccount.Sku.Name)"
Write-Information "Usage: $($Usage.CurrentValue) / $($Usage.Limit)"


#endregion
