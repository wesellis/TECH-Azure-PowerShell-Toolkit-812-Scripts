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
    [string]$AccountName
)

#region Functions

Write-Information "Monitoring Batch Account: $AccountName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get Batch Account details
$BatchAccount = Get-AzBatchAccount -ResourceGroupName $ResourceGroupName -Name $AccountName

Write-Information "Batch Account Information:"
Write-Information "  Name: $($BatchAccount.AccountName)"
Write-Information "  Location: $($BatchAccount.Location)"
Write-Information "  Provisioning State: $($BatchAccount.ProvisioningState)"
Write-Information "  Account Endpoint: $($BatchAccount.AccountEndpoint)"
Write-Information "  Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"
Write-Information "  Dedicated Core Quota: $($BatchAccount.DedicatedCoreQuota)"
Write-Information "  Low Priority Core Quota: $($BatchAccount.LowPriorityCoreQuota)"

if ($BatchAccount.AutoStorageAccountId) {
    $StorageAccountName = $BatchAccount.AutoStorageAccountId.Split('/')[-1]
    Write-Information "  Auto Storage Account: $StorageAccountName"
}

# Get batch context for detailed operations
try {
    $BatchContext = Get-AzBatchAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
    
    # Get pools information
    Write-Information "`nBatch Pools:"
    $Pools = Get-AzBatchPool -BatchContext $BatchContext
    
    if ($Pools.Count -eq 0) {
        Write-Information "  No pools configured"
    } else {
        foreach ($Pool in $Pools) {
            Write-Information "  - Pool: $($Pool.Id)"
            Write-Information "    State: $($Pool.State)"
            Write-Information "    VM Size: $($Pool.VmSize)"
            Write-Information "    Target Dedicated Nodes: $($Pool.TargetDedicatedComputeNodes)"
            Write-Information "    Current Dedicated Nodes: $($Pool.CurrentDedicatedComputeNodes)"
            Write-Information "    Target Low Priority Nodes: $($Pool.TargetLowPriorityComputeNodes)"
            Write-Information "    Current Low Priority Nodes: $($Pool.CurrentLowPriorityComputeNodes)"
            Write-Information "    Auto Scale Enabled: $($Pool.EnableAutoScale)"
            Write-Information "    ---"
        }
    }
    
    # Get jobs information
    Write-Information "`nBatch Jobs:"
    $Jobs = Get-AzBatchJob -BatchContext $BatchContext
    
    if ($Jobs.Count -eq 0) {
        Write-Information "  No active jobs"
    } else {
        foreach ($Job in $Jobs) {
            Write-Information "  - Job: $($Job.Id)"
            Write-Information "    State: $($Job.State)"
            Write-Information "    Pool: $($Job.PoolInformation.PoolId)"
            Write-Information "    Priority: $($Job.Priority)"
            Write-Information "    Creation Time: $($Job.CreationTime)"
            
            # Get task count for this job
            $TaskCounts = Get-AzBatchTaskCount -JobId $Job.Id -BatchContext $BatchContext -ErrorAction SilentlyContinue
            if ($TaskCounts) {
                Write-Information "    Active Tasks: $($TaskCounts.Active)"
                Write-Information "    Running Tasks: $($TaskCounts.Running)"
                Write-Information "    Completed Tasks: $($TaskCounts.Completed)"
                Write-Information "    Failed Tasks: $($TaskCounts.Failed)"
            }
            Write-Information "    ---"
        }
    }
    
} catch {
    Write-Information "`nDetailed pool and job information: Unable to retrieve (check permissions)"
    Write-Information "Error: $($_.Exception.Message)"
}

# Display quota information
Write-Information "`nQuota Information:"
Write-Information "  Dedicated Core Quota: $($BatchAccount.DedicatedCoreQuota)"
Write-Information "  Low Priority Core Quota: $($BatchAccount.LowPriorityCoreQuota)"
Write-Information "  Pool Quota: $($BatchAccount.PoolQuota)"
Write-Information "  Active Job and Job Schedule Quota: $($BatchAccount.ActiveJobAndJobScheduleQuota)"

Write-Information "`nBatch Account URLs:"
Write-Information "  Portal: https://portal.azure.com/#@/resource$($BatchAccount.Id)"
Write-Information "  Batch Explorer: https://azure.github.io/BatchExplorer/"

Write-Information "`nNext Steps for Optimization:"
Write-Information "1. Review pool utilization and scale settings"
Write-Information "2. Monitor job completion times and failure rates"
Write-Information "3. Optimize task distribution across nodes"
Write-Information "4. Consider using low-priority VMs for cost savings"
Write-Information "5. Implement auto-scaling for dynamic workloads"

Write-Information "`nBatch Account monitoring completed at $(Get-Date)"


#endregion
