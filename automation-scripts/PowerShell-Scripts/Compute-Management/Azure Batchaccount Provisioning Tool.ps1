<#
.SYNOPSIS
    Azure Batchaccount Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Batchaccount Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAccountName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountName,
    [string]$WEPoolAllocationMode = " BatchService"
)

Write-WELog " Provisioning Batch Account: $WEAccountName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Pool Allocation Mode: $WEPoolAllocationMode" " INFO"


if ($WEStorageAccountName) {
    Write-WELog " Storage Account: $WEStorageAccountName" " INFO"
    
    # Check if storage account exists
    $WEStorageAccount = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -Name $WEStorageAccountName -ErrorAction SilentlyContinue
    
    if (-not $WEStorageAccount) {
        Write-WELog " Creating storage account for Batch..." " INFO"
        $WEStorageAccount = New-AzStorageAccount -ErrorAction Stop `
            -ResourceGroupName $WEResourceGroupName `
            -Name $WEStorageAccountName `
            -Location $WELocation `
            -SkuName " Standard_LRS" `
            -Kind " StorageV2"
        
        Write-WELog " Storage account created: $($WEStorageAccount.StorageAccountName)" " INFO"
    } else {
        Write-WELog " Using existing storage account: $($WEStorageAccount.StorageAccountName)" " INFO"
    }
}


if ($WEStorageAccountName) {
   ;  $WEBatchAccount = New-AzBatchAccount -ErrorAction Stop `
        -ResourceGroupName $WEResourceGroupName `
        -Name $WEAccountName `
        -Location $WELocation `
        -AutoStorageAccountId $WEStorageAccount.Id
} else {
   ;  $WEBatchAccount = New-AzBatchAccount -ErrorAction Stop `
        -ResourceGroupName $WEResourceGroupName `
        -Name $WEAccountName `
        -Location $WELocation
}

Write-WELog " `nBatch Account $WEAccountName provisioned successfully" " INFO"
Write-WELog " Account Endpoint: $($WEBatchAccount.AccountEndpoint)" " INFO"
Write-WELog " Provisioning State: $($WEBatchAccount.ProvisioningState)" " INFO"
Write-WELog " Pool Allocation Mode: $($WEBatchAccount.PoolAllocationMode)" " INFO"

if ($WEStorageAccountName) {
    Write-WELog " Auto Storage Account: $($WEBatchAccount.AutoStorageAccountId.Split('/')[-1])" " INFO"
}

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Create pools for compute nodes" " INFO"
Write-WELog " 2. Submit jobs and tasks" " INFO"
Write-WELog " 3. Monitor job execution through Azure Portal" " INFO"

Write-WELog " `nBatch Account provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
