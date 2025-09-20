#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Provision Azure Storage Account

.DESCRIPTION
    Create and configure Azure Storage Account with specified settings
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$Location,
    [string]$SkuName = "Standard_LRS",
    [string]$Kind = "StorageV2",
    [string]$AccessTier = "Hot"
)
Write-Host "Provisioning Storage Account: $StorageAccountName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName"
Write-Host "Kind: $Kind"
Write-Host "Access Tier: $AccessTier"
# Create the storage account
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
Write-Host "Storage Account $StorageAccountName provisioned successfully"
Write-Host "Primary Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)"

