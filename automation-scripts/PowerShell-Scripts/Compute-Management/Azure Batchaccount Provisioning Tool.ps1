<#
.SYNOPSIS
    Azure Batchaccount Provisioning Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AccountName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    [string]$PoolAllocationMode = "BatchService"
)
Write-Host "Provisioning Batch Account: $AccountName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Pool Allocation Mode: $PoolAllocationMode"
if ($StorageAccountName) {
    Write-Host "Storage Account: $StorageAccountName"
    # Check if storage account exists
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $StorageAccount) {
        Write-Host "Creating storage account for Batch..."
        $params = @{
            ResourceGroupName = $ResourceGroupName
            SkuName = "Standard_LRS"
            Location = $Location
            Kind = "StorageV2"  Write-Host "Storage account created: $($StorageAccount.StorageAccountName)" "INFO" } else { Write-Host "Using existing storage account: $($StorageAccount.StorageAccountName)" }"
            ErrorAction = "Stop"
            Name = $StorageAccountName
        }
        $StorageAccount @params
}
if ($StorageAccountName) {
   $params = @{
       ErrorAction = "Stop"
       AutoStorageAccountId = $StorageAccount.Id
       ResourceGroupName = $ResourceGroupName
       Name = $AccountName
       Location = $Location
   }
   ; @params
} else {
   $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $AccountName
       Location = $Location
   }
   ; @params
}
Write-Host " `nBatch Account $AccountName provisioned successfully"
Write-Host "Account Endpoint: $($BatchAccount.AccountEndpoint)"
Write-Host "Provisioning State: $($BatchAccount.ProvisioningState)"
Write-Host "Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"
if ($StorageAccountName) {
    Write-Host "Auto Storage Account: $($BatchAccount.AutoStorageAccountId.Split('/')[-1])"
}
Write-Host " `nNext Steps:"
Write-Host " 1. Create pools for compute nodes"
Write-Host " 2. Submit jobs and tasks"
Write-Host " 3. Monitor job execution through Azure Portal"
Write-Host " `nBatch Account provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n