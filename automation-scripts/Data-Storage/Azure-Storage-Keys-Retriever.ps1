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

Write-Host "Retrieving access keys for Storage Account: $StorageAccountName"

$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

Write-Host "`nStorage Account Keys:"
Write-Host "  Primary Key: $($Keys[0].Value)"
Write-Host "  Secondary Key: $($Keys[1].Value)"

Write-Host "`nConnection Strings:"
Write-Host "  Primary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[0].Value);EndpointSuffix=core.windows.net"
Write-Host "  Secondary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[1].Value);EndpointSuffix=core.windows.net"
