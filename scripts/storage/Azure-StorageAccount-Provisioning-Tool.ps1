#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Provision Azure Storage Account

.DESCRIPTION
    Create and configure Azure Storage Account with specified settings
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$Location,
    [string]$SkuName = "Standard_LRS",
    [string]$Kind = "StorageV2",
    [string]$AccessTier = "Hot"
)
Write-Output "Provisioning Storage Account: $StorageAccountName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $SkuName"
Write-Output "Kind: $Kind"
Write-Output "Access Tier: $AccessTier"
$params = @{
    ResourceGroupName = $ResourceGroupName
    AccessTier = $AccessTier
    SkuName = $SkuName
    Location = $Location
    EnableHttpsTrafficOnly = $true
    Kind = $Kind
    Name = $StorageAccountName
}
$StorageAccount = New-AzStorageAccount @params
Write-Output "Storage Account $StorageAccountName provisioned successfully"
Write-Output "Primary Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)"



