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

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [string]$TableName
)
Write-Output "Creating Table Storage: $TableName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$Table = New-AzStorageTable -Name $TableName -Context $Context
Write-Output "Table Storage created successfully:"
Write-Output "Name: $($Table.Name)"
Write-Output "Storage Account: $StorageAccountName"
Write-Output "Context: $($Context.StorageAccountName)"
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Key = $Keys[0].Value
Write-Output "`nConnection Information:"
Write-Output "Table Endpoint: https://$StorageAccountName.table.core.windows.net/"
Write-Output "Table Name: $TableName"
Write-Output "Access Key: $($Key.Substring(0,8))..."
Write-Output "`nConnection String:"
Write-Output "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$Key;TableEndpoint=https://$StorageAccountName.table.core.windows.net/;"
Write-Output "`nTable Storage Features:"
Write-Output "NoSQL key-value store"
Write-Output "Partition and row key structure"
Write-Output "Automatic scaling"
Write-Output "REST API access"



