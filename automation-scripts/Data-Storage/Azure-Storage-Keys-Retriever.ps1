<#
.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName
)
Write-Host "Retrieving access keys for Storage Account: $StorageAccountName"
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
Write-Host "`nStorage Account Keys:"
Write-Host "Primary Key: $($Keys[0].Value)"
Write-Host "Secondary Key: $($Keys[1].Value)"
Write-Host "`nConnection Strings:"
Write-Host "Primary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[0].Value);EndpointSuffix=core.windows.net"
Write-Host "Secondary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[1].Value);EndpointSuffix=core.windows.net"

