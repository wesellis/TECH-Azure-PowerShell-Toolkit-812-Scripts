#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Batchaccount Performance Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Batchaccount Performance Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



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
    [string]$WEAccountName
)

#region Functions

Write-WELog " Monitoring Batch Account: $WEAccountName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WEBatchAccount = Get-AzBatchAccount -ResourceGroupName $WEResourceGroupName -Name $WEAccountName

Write-WELog " Batch Account Information:" " INFO"
Write-WELog "  Name: $($WEBatchAccount.AccountName)" " INFO"
Write-WELog "  Location: $($WEBatchAccount.Location)" " INFO"
Write-WELog "  Provisioning State: $($WEBatchAccount.ProvisioningState)" " INFO"
Write-WELog "  Account Endpoint: $($WEBatchAccount.AccountEndpoint)" " INFO"
Write-WELog "  Pool Allocation Mode: $($WEBatchAccount.PoolAllocationMode)" " INFO"
Write-WELog "  Dedicated Core Quota: $($WEBatchAccount.DedicatedCoreQuota)" " INFO"
Write-WELog "  Low Priority Core Quota: $($WEBatchAccount.LowPriorityCoreQuota)" " INFO"

if ($WEBatchAccount.AutoStorageAccountId) {
    $WEStorageAccountName = $WEBatchAccount.AutoStorageAccountId.Split('/')[-1]
    Write-WELog "  Auto Storage Account: $WEStorageAccountName" " INFO"
}


try {
    $WEBatchContext = Get-AzBatchAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEAccountName
    
    # Get pools information
    Write-WELog " `nBatch Pools:" " INFO"
    $WEPools = Get-AzBatchPool -BatchContext $WEBatchContext
    
    if ($WEPools.Count -eq 0) {
        Write-WELog "  No pools configured" " INFO"
    } else {
        foreach ($WEPool in $WEPools) {
            Write-WELog "  - Pool: $($WEPool.Id)" " INFO"
            Write-WELog "    State: $($WEPool.State)" " INFO"
            Write-WELog "    VM Size: $($WEPool.VmSize)" " INFO"
            Write-WELog "    Target Dedicated Nodes: $($WEPool.TargetDedicatedComputeNodes)" " INFO"
            Write-WELog "    Current Dedicated Nodes: $($WEPool.CurrentDedicatedComputeNodes)" " INFO"
            Write-WELog "    Target Low Priority Nodes: $($WEPool.TargetLowPriorityComputeNodes)" " INFO"
            Write-WELog "    Current Low Priority Nodes: $($WEPool.CurrentLowPriorityComputeNodes)" " INFO"
            Write-WELog "    Auto Scale Enabled: $($WEPool.EnableAutoScale)" " INFO"
            Write-WELog "    ---" " INFO"
        }
    }
    
    # Get jobs information
    Write-WELog " `nBatch Jobs:" " INFO"
   ;  $WEJobs = Get-AzBatchJob -BatchContext $WEBatchContext
    
    if ($WEJobs.Count -eq 0) {
        Write-WELog "  No active jobs" " INFO"
    } else {
        foreach ($WEJob in $WEJobs) {
            Write-WELog "  - Job: $($WEJob.Id)" " INFO"
            Write-WELog "    State: $($WEJob.State)" " INFO"
            Write-WELog "    Pool: $($WEJob.PoolInformation.PoolId)" " INFO"
            Write-WELog "    Priority: $($WEJob.Priority)" " INFO"
            Write-WELog "    Creation Time: $($WEJob.CreationTime)" " INFO"
            
            # Get task count for this job
           ;  $WETaskCounts = Get-AzBatchTaskCount -JobId $WEJob.Id -BatchContext $WEBatchContext -ErrorAction SilentlyContinue
            if ($WETaskCounts) {
                Write-WELog "    Active Tasks: $($WETaskCounts.Active)" " INFO"
                Write-WELog "    Running Tasks: $($WETaskCounts.Running)" " INFO"
                Write-WELog "    Completed Tasks: $($WETaskCounts.Completed)" " INFO"
                Write-WELog "    Failed Tasks: $($WETaskCounts.Failed)" " INFO"
            }
            Write-WELog "    ---" " INFO"
        }
    }
    
} catch {
    Write-WELog " `nDetailed pool and job information: Unable to retrieve (check permissions)" " INFO"
    Write-WELog " Error: $($_.Exception.Message)" " INFO"
}


Write-WELog " `nQuota Information:" " INFO"
Write-WELog "  Dedicated Core Quota: $($WEBatchAccount.DedicatedCoreQuota)" " INFO"
Write-WELog "  Low Priority Core Quota: $($WEBatchAccount.LowPriorityCoreQuota)" " INFO"
Write-WELog "  Pool Quota: $($WEBatchAccount.PoolQuota)" " INFO"
Write-WELog "  Active Job and Job Schedule Quota: $($WEBatchAccount.ActiveJobAndJobScheduleQuota)" " INFO"

Write-WELog " `nBatch Account URLs:" " INFO"
Write-WELog "  Portal: https://portal.azure.com/#@/resource$($WEBatchAccount.Id)" " INFO"
Write-WELog "  Batch Explorer: https://azure.github.io/BatchExplorer/" " INFO"

Write-WELog " `nNext Steps for Optimization:" " INFO"
Write-WELog " 1. Review pool utilization and scale settings" " INFO"
Write-WELog " 2. Monitor job completion times and failure rates" " INFO"
Write-WELog " 3. Optimize task distribution across nodes" " INFO"
Write-WELog " 4. Consider using low-priority VMs for cost savings" " INFO"
Write-WELog " 5. Implement auto-scaling for dynamic workloads" " INFO"

Write-WELog " `nBatch Account monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
