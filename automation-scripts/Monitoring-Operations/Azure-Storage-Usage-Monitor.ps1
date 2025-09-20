#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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

