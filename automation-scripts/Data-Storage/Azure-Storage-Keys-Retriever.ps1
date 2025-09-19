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
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName
)

#region Functions

Write-Information "Retrieving access keys for Storage Account: $StorageAccountName"

$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName

Write-Information "`nStorage Account Keys:"
Write-Information "  Primary Key: $($Keys[0].Value)"
Write-Information "  Secondary Key: $($Keys[1].Value)"

Write-Information "`nConnection Strings:"
Write-Information "  Primary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[0].Value);EndpointSuffix=core.windows.net"
Write-Information "  Secondary: DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$($Keys[1].Value);EndpointSuffix=core.windows.net"


#endregion
