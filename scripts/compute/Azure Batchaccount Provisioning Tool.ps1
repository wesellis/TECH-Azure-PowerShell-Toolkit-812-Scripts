#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure Batchaccount Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
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
Write-Output "Provisioning Batch Account: $AccountName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "Pool Allocation Mode: $PoolAllocationMode"
if ($StorageAccountName) {
    Write-Output "Storage Account: $StorageAccountName"
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    if (-not $StorageAccount) {
        Write-Output "Creating storage account for Batch..."
    $params = @{
            ResourceGroupName = $ResourceGroupName
            SkuName = "Standard_LRS"
            Location = $Location
            Kind = "StorageV2"  Write-Output "Storage account created: $($StorageAccount.StorageAccountName)" "INFO" } else { Write-Output "Using existing storage account: $($StorageAccount.StorageAccountName)" }"
            ErrorAction = "Stop"
            Name = $StorageAccountName
        }
    [string]$StorageAccount @params
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
Write-Output " `nBatch Account $AccountName provisioned successfully"
Write-Output "Account Endpoint: $($BatchAccount.AccountEndpoint)"
Write-Output "Provisioning State: $($BatchAccount.ProvisioningState)"
Write-Output "Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"
if ($StorageAccountName) {
    Write-Output "Auto Storage Account: $($BatchAccount.AutoStorageAccountId.Split('/')[-1])"
}
Write-Output " `nNext Steps:"
Write-Output " 1. Create pools for compute nodes"
Write-Output " 2. Submit jobs and tasks"
Write-Output " 3. Monitor job execution through Azure Portal"
Write-Output " `nBatch Account provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
