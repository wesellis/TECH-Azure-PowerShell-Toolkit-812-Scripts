<#
.SYNOPSIS
    Provisions Azure Batch accounts with optional storage integration

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
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
    # Test Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    Write-Host "Provisioning Batch Account: $AccountName" -ForegroundColor Yellow
    # Check if resource group exists
    Write-Host "Validating resource group..." -ForegroundColor Yellow
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        throw "Resource group '$ResourceGroupName' not found"
    }
    # Check Batch account name availability
    Write-Host "Checking Batch account name availability..." -ForegroundColor Yellow
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
    # Handle storage account for auto-storage
    $storageAccount = $null
    if ($StorageAccountName) {
        Write-Host "Configuring storage account..." -ForegroundColor Yellow
        # Check if storage account exists
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
        if (-not $storageAccount) {
            Write-Host "Creating storage account for Batch..." -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess($StorageAccountName, "Create storage account")) {
                $storageParams = @{
                    ResourceGroupName = $ResourceGroupName
                    Name = $StorageAccountName
                    Location = $Location
                    SkuName = "Standard_LRS"
                    Kind = "StorageV2"
                }
                $storageAccount = New-AzStorageAccount @storageParams
                Write-Host "Storage account created: $($storageAccount.StorageAccountName)" -ForegroundColor Green
            }
        } else {
            Write-Host "Using existing storage account: $($storageAccount.StorageAccountName)" -ForegroundColor Green
        }
    }
    # Confirmation
    if (-not $Force) {
        Write-Host "`nBatch Account Configuration:" -ForegroundColor Cyan
        Write-Host "Account Name: $AccountName"
        Write-Host "Resource Group: $ResourceGroupName"
        Write-Host "Location: $Location"
        Write-Host "Pool Allocation Mode: $PoolAllocationMode"
        if ($StorageAccountName) {
            Write-Host "Auto-Storage Account: $StorageAccountName"
        }
        $confirmation = Read-Host "`nCreate Batch account? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    # Create the Batch Account
    Write-Host "`nCreating Batch account..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($AccountName, "Create Batch account")) {
        $batchParams = @{
            ResourceGroupName = $ResourceGroupName
            AccountName = $AccountName
            Location = $Location
            PoolAllocationMode = $PoolAllocationMode
        }
        if ($storageAccount) {
            $batchParams.AutoStorageAccountId = $storageAccount.Id
        }
        $batchAccount = New-AzBatchAccount @batchParams
        Write-Host "Batch Account provisioned successfully!" -ForegroundColor Green
        Write-Host "`nAccount Details:" -ForegroundColor Cyan
        Write-Host "Name: $($batchAccount.AccountName)"
        Write-Host "Account Endpoint: $($batchAccount.AccountEndpoint)"
        Write-Host "Provisioning State: $($batchAccount.ProvisioningState)"
        Write-Host "Pool Allocation Mode: $($batchAccount.PoolAllocationMode)"
        Write-Host "Location: $($batchAccount.Location)"
        if ($storageAccount) {
            Write-Host "Auto Storage Account: $($storageAccount.StorageAccountName)" -ForegroundColor Green
        }
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Create compute pools for your workloads"
        Write-Host "2. Configure applications and application packages"
        Write-Host "3. Submit jobs and tasks to the Batch service"
        Write-Host "4. Monitor job execution through Azure Portal or CLI"
        if (-not $storageAccount) {
            Write-Host "5. Consider adding auto-storage for easier data management"
        }
        Write-Host "`nUseful Commands:" -ForegroundColor Cyan
        Write-Host "Get account keys: Get-AzBatchAccountKey -AccountName $AccountName -ResourceGroupName $ResourceGroupName"
        Write-Host "List pools: Get-AzBatchPool -BatchContext (Get-AzBatchAccount -AccountName $AccountName)"
    
} catch {
    Write-Error "Failed to provision Batch account: $_"
    throw
}\n