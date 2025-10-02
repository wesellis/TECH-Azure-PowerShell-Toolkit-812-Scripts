#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$StorageAccountName
)
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$Usage = Get-AzStorageUsage -Context $Context
Write-Output "Storage Account: $($StorageAccount.StorageAccountName)"
Write-Output "Resource Group: $($StorageAccount.ResourceGroupName)"
Write-Output "Location: $($StorageAccount.Location)"
Write-Output "SKU: $($StorageAccount.Sku.Name)"
Write-Output "Usage: $($Usage.CurrentValue) / $($Usage.Limit)"



