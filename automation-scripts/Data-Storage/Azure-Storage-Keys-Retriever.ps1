# ============================================================================
# Script Name: Azure Storage Account Key Retriever
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Retrieves access keys for Azure Storage Account
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName
)

Write-Information "Retrieving access keys for Storage Account: $StorageAccountName"

$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

Write-Information "`nStorage Account Keys:"
Write-Information "  Primary Key: $($Keys[0].Value)"
Write-Information "  Secondary Key: $($Keys[1].Value)"

Write-Information "`nConnection Strings:"
Write-Information "  Primary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[0].Value);EndpointSuffix=core.windows.net"
Write-Information "  Secondary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[1].Value);EndpointSuffix=core.windows.net"
