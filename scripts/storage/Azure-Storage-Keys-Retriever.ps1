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
    [string]$StorageAccountName
)
Write-Output "Retrieving access keys for Storage Account: $StorageAccountName"
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
Write-Output "`nStorage Account Keys:"
Write-Output "Primary Key: $($Keys[0].Value)"
Write-Output "Secondary Key: $($Keys[1].Value)"
Write-Output "`nConnection Strings:"
Write-Output "Primary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[0].Value);EndpointSuffix=core.windows.net"
Write-Output "Secondary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[1].Value);EndpointSuffix=core.windows.net"



