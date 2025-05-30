# ============================================================================
# Script Name: Azure Batch Account Performance Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Batch Account status, pools, and job execution metrics
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AccountName
)

Write-Host "Monitoring Batch Account: $AccountName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get Batch Account details
$BatchAccount = Get-AzBatchAccount -ResourceGroupName $ResourceGroupName -Name $AccountName

Write-Host "Batch Account Information:"
Write-Host "  Name: $($BatchAccount.AccountName)"
Write-Host "  Location: $($BatchAccount.Location)"
Write-Host "  Provisioning State: $($BatchAccount.ProvisioningState)"
Write-Host "  Account Endpoint: $($BatchAccount.AccountEndpoint)"
Write-Host "  Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"
Write-Host "  Dedicated Core Quota: $($BatchAccount.DedicatedCoreQuota)"
Write-Host "  Low Priority Core Quota: $($BatchAccount.LowPriorityCoreQuota)"

if ($BatchAccount.AutoStorageAccountId) {
    $StorageAccountName = $BatchAccount.AutoStorageAccountId.Split('/')[-1]
    Write-Host "  Auto Storage Account: $StorageAccountName"
}

# Get batch context for detailed operations
try {
    $BatchContext = Get-AzBatchAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
    
    # Get pools information
    Write-Host "`nBatch Pools:"
    $Pools = Get-AzBatchPool -BatchContext $BatchContext
    
    if ($Pools.Count -eq 0) {
        Write-Host "  No pools configured"
    } else {
        foreach ($Pool in $Pools) {
            Write-Host "  - Pool: $($Pool.Id)"
            Write-Host "    State: $($Pool.State)"
            Write-Host "    VM Size: $($Pool.VmSize)"
            Write-Host "    Target Dedicated Nodes: $($Pool.TargetDedicatedComputeNodes)"
            Write-Host "    Current Dedicated Nodes: $($Pool.CurrentDedicatedComputeNodes)"
            Write-Host "    Target Low Priority Nodes: $($Pool.TargetLowPriorityComputeNodes)"
            Write-Host "    Current Low Priority Nodes: $($Pool.CurrentLowPriorityComputeNodes)"
            Write-Host "    Auto Scale Enabled: $($Pool.EnableAutoScale)"
            Write-Host "    ---"
        }
    }
    
    # Get jobs information
    Write-Host "`nBatch Jobs:"
    $Jobs = Get-AzBatchJob -BatchContext $BatchContext
    
    if ($Jobs.Count -eq 0) {
        Write-Host "  No active jobs"
    } else {
        foreach ($Job in $Jobs) {
            Write-Host "  - Job: $($Job.Id)"
            Write-Host "    State: $($Job.State)"
            Write-Host "    Pool: $($Job.PoolInformation.PoolId)"
            Write-Host "    Priority: $($Job.Priority)"
            Write-Host "    Creation Time: $($Job.CreationTime)"
            
            # Get task count for this job
            $TaskCounts = Get-AzBatchTaskCount -JobId $Job.Id -BatchContext $BatchContext -ErrorAction SilentlyContinue
            if ($TaskCounts) {
                Write-Host "    Active Tasks: $($TaskCounts.Active)"
                Write-Host "    Running Tasks: $($TaskCounts.Running)"
                Write-Host "    Completed Tasks: $($TaskCounts.Completed)"
                Write-Host "    Failed Tasks: $($TaskCounts.Failed)"
            }
            Write-Host "    ---"
        }
    }
    
} catch {
    Write-Host "`nDetailed pool and job information: Unable to retrieve (check permissions)"
    Write-Host "Error: $($_.Exception.Message)"
}

# Display quota information
Write-Host "`nQuota Information:"
Write-Host "  Dedicated Core Quota: $($BatchAccount.DedicatedCoreQuota)"
Write-Host "  Low Priority Core Quota: $($BatchAccount.LowPriorityCoreQuota)"
Write-Host "  Pool Quota: $($BatchAccount.PoolQuota)"
Write-Host "  Active Job and Job Schedule Quota: $($BatchAccount.ActiveJobAndJobScheduleQuota)"

Write-Host "`nBatch Account URLs:"
Write-Host "  Portal: https://portal.azure.com/#@/resource$($BatchAccount.Id)"
Write-Host "  Batch Explorer: https://azure.github.io/BatchExplorer/"

Write-Host "`nNext Steps for Optimization:"
Write-Host "1. Review pool utilization and scale settings"
Write-Host "2. Monitor job completion times and failure rates"
Write-Host "3. Optimize task distribution across nodes"
Write-Host "4. Consider using low-priority VMs for cost savings"
Write-Host "5. Implement auto-scaling for dynamic workloads"

Write-Host "`nBatch Account monitoring completed at $(Get-Date)"
