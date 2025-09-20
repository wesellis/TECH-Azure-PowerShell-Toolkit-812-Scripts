#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [string]$TableName
)
Write-Host "Creating Table Storage: $TableName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$Table = New-AzStorageTable -Name $TableName -Context $Context
Write-Host "Table Storage created successfully:"
Write-Host "Name: $($Table.Name)"
Write-Host "Storage Account: $StorageAccountName"
Write-Host "Context: $($Context.StorageAccountName)"
# Get connection info
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Key = $Keys[0].Value
Write-Host "`nConnection Information:"
Write-Host "Table Endpoint: https://$StorageAccountName.table.core.windows.net/"
Write-Host "Table Name: $TableName"
Write-Host "Access Key: $($Key.Substring(0,8))..."
Write-Host "`nConnection String:"
Write-Host "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$Key;TableEndpoint=https://$StorageAccountName.table.core.windows.net/;"
Write-Host "`nTable Storage Features:"
Write-Host "NoSQL key-value store"
Write-Host "Partition and row key structure"
Write-Host "Automatic scaling"
Write-Host "REST API access"

