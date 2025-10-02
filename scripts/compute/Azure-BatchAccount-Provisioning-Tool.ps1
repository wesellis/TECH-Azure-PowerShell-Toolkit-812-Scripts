#Requires -Version 7.4
#Requires -Modules Az.Storage
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Provisions Azure Batch accounts with optional storage integration

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Creates Azure Batch accounts with optional auto-storage configuration.
    Supports both BatchService and UserSubscription pool allocation modes.
.PARAMETER ResourceGroupName
    Name of the resource group for the Batch account
.PARAMETER AccountName
    Name of the Batch account (must be globally unique)
.PARAMETER Location
    Azure region for the Batch account
.PARAMETER StorageAccountName
    Name of storage account for auto-storage (optional)
.PARAMETER PoolAllocationMode
    Pool allocation mode: BatchService or UserSubscription
.PARAMETER Force
    Skip confirmation
    .\Azure-BatchAccount-Provisioning-Tool.ps1 -ResourceGroupName "RG-Batch" -AccountName "mybatchaccount123" -Location "East US"
    .\Azure-BatchAccount-Provisioning-Tool.ps1 -ResourceGroupName "RG-Batch" -AccountName "mybatchaccount123" -Location "East US" -StorageAccountName "batchstorage123"
param(
[Parameter(Mandatory = $true)]
)
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]{3,24}$')]
    [string]$AccountName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidatePattern('^[a-z0-9]{3,24}$')]
    [string]$StorageAccountName,
    [Parameter()]
    [ValidateSet("BatchService", "UserSubscription")]
    [string]$PoolAllocationMode = "BatchService",
    [Parameter()]
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    Write-Host "Provisioning Batch Account: $AccountName" -ForegroundColor Green
    Write-Host "Validating resource group..." -ForegroundColor Green
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        throw "Resource group '$ResourceGroupName' not found"
    }
    Write-Host "Checking Batch account name availability..." -ForegroundColor Green
    try {
        $availability = Test-AzBatchAccountNameAvailability -Name $AccountName
        if (-not $availability.NameAvailable) {
            throw "Batch account name '$AccountName' is not available: $($availability.Reason)"
        }
        Write-Host "Batch account name is available" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not verify name availability: $_"
    }
    $StorageAccount = $null
    if ($StorageAccountName) {
        Write-Host "Configuring storage account..." -ForegroundColor Green
        $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
        if (-not $StorageAccount) {
            Write-Host "Creating storage account for Batch..." -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess($StorageAccountName, "Create storage account")) {
                $StorageParams = @{
                    ResourceGroupName = $ResourceGroupName
                    Name = $StorageAccountName
                    Location = $Location
                    SkuName = "Standard_LRS"
                    Kind = "StorageV2"
                }
                $StorageAccount = New-AzStorageAccount @storageParams
                Write-Host "Storage account created: $($StorageAccount.StorageAccountName)" -ForegroundColor Green
            }
        } else {
            Write-Host "Using existing storage account: $($StorageAccount.StorageAccountName)" -ForegroundColor Green
        }
    }
    if (-not $Force) {
        Write-Host "`nBatch Account Configuration:" -ForegroundColor Green
        Write-Output "Account Name: $AccountName"
        Write-Output "Resource Group: $ResourceGroupName"
        Write-Output "Location: $Location"
        Write-Output "Pool Allocation Mode: $PoolAllocationMode"
        if ($StorageAccountName) {
            Write-Output "Auto-Storage Account: $StorageAccountName"
        }
        $confirmation = Read-Host "`nCreate Batch account? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "`nCreating Batch account..." -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($AccountName, "Create Batch account")) {
        $BatchParams = @{
            ResourceGroupName = $ResourceGroupName
            AccountName = $AccountName
            Location = $Location
            PoolAllocationMode = $PoolAllocationMode
        }
        if ($StorageAccount) {
            $BatchParams.AutoStorageAccountId = $StorageAccount.Id
        }
        $BatchAccount = New-AzBatchAccount @batchParams
        Write-Host "Batch Account provisioned successfully!" -ForegroundColor Green
        Write-Host "`nAccount Details:" -ForegroundColor Green
        Write-Output "Name: $($BatchAccount.AccountName)"
        Write-Output "Account Endpoint: $($BatchAccount.AccountEndpoint)"
        Write-Output "Provisioning State: $($BatchAccount.ProvisioningState)"
        Write-Output "Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"
        Write-Output "Location: $($BatchAccount.Location)"
        if ($StorageAccount) {
            Write-Host "Auto Storage Account: $($StorageAccount.StorageAccountName)" -ForegroundColor Green
        }
        Write-Host "`nNext Steps:" -ForegroundColor Green
        Write-Output "1. Create compute pools for your workloads"
        Write-Output "2. Configure applications and application packages"
        Write-Output "3. Submit jobs and tasks to the Batch service"
        Write-Output "4. Monitor job execution through Azure Portal or CLI"
        if (-not $StorageAccount) {
            Write-Output "5. Consider adding auto-storage for easier data management"
        }
        Write-Host "`nUseful Commands:" -ForegroundColor Green
        Write-Output "Get account keys: Get-AzBatchAccountKey -AccountName $AccountName -ResourceGroupName $ResourceGroupName"
        Write-Output "List pools: Get-AzBatchPool -BatchContext (Get-AzBatchAccount -AccountName $AccountName)"

} catch {
    Write-Error "Failed to provision Batch account: $_"
    throw`n}
