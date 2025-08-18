# ============================================================================
# Script Name: Azure Table Storage Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Table Storage for NoSQL structured data
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$TableName
)

Write-Information "Creating Table Storage: $TableName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$Table = New-AzStorageTable -Name $TableName -Context $Context

Write-Information "✅ Table Storage created successfully:"
Write-Information "  Name: $($Table.Name)"
Write-Information "  Storage Account: $StorageAccountName"
Write-Information "  Context: $($Context.StorageAccountName)"

# Get connection info
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Key = $Keys[0].Value

Write-Information "`nConnection Information:"
Write-Information "  Table Endpoint: https://$StorageAccountName.table.core.windows.net/"
Write-Information "  Table Name: $TableName"
Write-Information "  Access Key: $($Key.Substring(0,8))..."

Write-Information "`nConnection String:"
Write-Information "  DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$Key;TableEndpoint=https://$StorageAccountName.table.core.windows.net/;"

Write-Information "`nTable Storage Features:"
Write-Information "• NoSQL key-value store"
Write-Information "• Partition and row key structure"
Write-Information "• Automatic scaling"
Write-Information "• REST API access"
