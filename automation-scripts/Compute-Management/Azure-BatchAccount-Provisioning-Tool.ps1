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
    [string]$AccountName,
    [string]$Location,
    [string]$StorageAccountName,
    [string]$PoolAllocationMode = "BatchService"
)

#region Functions

Write-Information "Provisioning Batch Account: $AccountName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Pool Allocation Mode: $PoolAllocationMode"

# Create storage account for Batch if specified
if ($StorageAccountName) {
    Write-Information "Storage Account: $StorageAccountName"
    
    # Check if storage account exists
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    
    if (-not $StorageAccount) {
        Write-Information "Creating storage account for Batch..."
        $params = @{
            ResourceGroupName = $ResourceGroupName
            SkuName = "Standard_LRS"
            Location = $Location
            Kind = "StorageV2"  Write-Information "Storage account created: $($StorageAccount.StorageAccountName)" } else { Write-Information "Using existing storage account: $($StorageAccount.StorageAccountName)" }"
            ErrorAction = "Stop"
            Name = $StorageAccountName
        }
        $StorageAccount @params
}

# Create the Batch Account
if ($StorageAccountName) {
    $params = @{
        ErrorAction = "Stop"
        AutoStorageAccountId = $StorageAccount.Id
        ResourceGroupName = $ResourceGroupName
        Name = $AccountName
        Location = $Location
    }
    $BatchAccount @params
} else {
    $params = @{
        ErrorAction = "Stop"
        ResourceGroupName = $ResourceGroupName
        Name = $AccountName
        Location = $Location
    }
    $BatchAccount @params
}

Write-Information "`nBatch Account $AccountName provisioned successfully"
Write-Information "Account Endpoint: $($BatchAccount.AccountEndpoint)"
Write-Information "Provisioning State: $($BatchAccount.ProvisioningState)"
Write-Information "Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"

if ($StorageAccountName) {
    Write-Information "Auto Storage Account: $($BatchAccount.AutoStorageAccountId.Split('/')[-1])"
}

Write-Information "`nNext Steps:"
Write-Information "1. Create pools for compute nodes"
Write-Information "2. Submit jobs and tasks"
Write-Information "3. Monitor job execution through Azure Portal"

Write-Information "`nBatch Account provisioning completed at $(Get-Date)"


#endregion
