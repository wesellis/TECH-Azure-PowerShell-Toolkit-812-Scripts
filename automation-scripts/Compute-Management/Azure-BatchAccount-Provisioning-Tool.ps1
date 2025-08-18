# ============================================================================
# Script Name: Azure Batch Account Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Batch accounts for large-scale parallel computing workloads
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AccountName,
    [string]$Location,
    [string]$StorageAccountName,
    [string]$PoolAllocationMode = "BatchService"
)

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
        $StorageAccount = New-AzStorageAccount -ErrorAction Stop `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -Location $Location `
            -SkuName "Standard_LRS" `
            -Kind "StorageV2"
        
        Write-Information "Storage account created: $($StorageAccount.StorageAccountName)"
    } else {
        Write-Information "Using existing storage account: $($StorageAccount.StorageAccountName)"
    }
}

# Create the Batch Account
if ($StorageAccountName) {
    $BatchAccount = New-AzBatchAccount -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $AccountName `
        -Location $Location `
        -AutoStorageAccountId $StorageAccount.Id
} else {
    $BatchAccount = New-AzBatchAccount -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $AccountName `
        -Location $Location
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
