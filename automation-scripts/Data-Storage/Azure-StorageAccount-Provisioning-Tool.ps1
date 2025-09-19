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
    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$Location,
    [string]$SkuName = "Standard_LRS",
    [string]$Kind = "StorageV2",
    [string]$AccessTier = "Hot"
)

#region Functions

Write-Information "Provisioning Storage Account: $StorageAccountName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName"
Write-Information "Kind: $Kind"
Write-Information "Access Tier: $AccessTier"

# Create the storage account
$params = @{
    ResourceGroupName = $ResourceGroupName
    AccessTier = $AccessTier
    SkuName = $SkuName
    Location = $Location
    EnableHttpsTrafficOnly = $true
    Kind = $Kind
    ErrorAction = "Stop"
    Name = $StorageAccountName
}
$StorageAccount @params

Write-Information "Storage Account $StorageAccountName provisioned successfully"
Write-Information "Primary Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)"


#endregion
