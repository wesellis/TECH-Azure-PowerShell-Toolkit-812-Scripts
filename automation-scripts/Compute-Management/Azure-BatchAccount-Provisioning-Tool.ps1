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

Write-Host "Provisioning Batch Account: $AccountName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Pool Allocation Mode: $PoolAllocationMode"

# Create storage account for Batch if specified
if ($StorageAccountName) {
    Write-Host "Storage Account: $StorageAccountName"
    
    # Check if storage account exists
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    
    if (-not $StorageAccount) {
        Write-Host "Creating storage account for Batch..."
        $StorageAccount = New-AzStorageAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -Location $Location `
            -SkuName "Standard_LRS" `
            -Kind "StorageV2"
        
        Write-Host "Storage account created: $($StorageAccount.StorageAccountName)"
    } else {
        Write-Host "Using existing storage account: $($StorageAccount.StorageAccountName)"
    }
}

# Create the Batch Account
if ($StorageAccountName) {
    $BatchAccount = New-AzBatchAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $AccountName `
        -Location $Location `
        -AutoStorageAccountId $StorageAccount.Id
} else {
    $BatchAccount = New-AzBatchAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $AccountName `
        -Location $Location
}

Write-Host "`nBatch Account $AccountName provisioned successfully"
Write-Host "Account Endpoint: $($BatchAccount.AccountEndpoint)"
Write-Host "Provisioning State: $($BatchAccount.ProvisioningState)"
Write-Host "Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"

if ($StorageAccountName) {
    Write-Host "Auto Storage Account: $($BatchAccount.AutoStorageAccountId.Split('/')[-1])"
}

Write-Host "`nNext Steps:"
Write-Host "1. Create pools for compute nodes"
Write-Host "2. Submit jobs and tasks"
Write-Host "3. Monitor job execution through Azure Portal"

Write-Host "`nBatch Account provisioning completed at $(Get-Date)"
