#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AccountName
)
Write-Output "Monitoring Batch Account: $AccountName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$BatchAccount = Get-AzBatchAccount -ResourceGroupName $ResourceGroupName -Name $AccountName
Write-Output "Batch Account Information:"
Write-Output "Name: $($BatchAccount.AccountName)"
Write-Output "Location: $($BatchAccount.Location)"
Write-Output "Provisioning State: $($BatchAccount.ProvisioningState)"
Write-Output "Account Endpoint: $($BatchAccount.AccountEndpoint)"
Write-Output "Pool Allocation Mode: $($BatchAccount.PoolAllocationMode)"
Write-Output "Dedicated Core Quota: $($BatchAccount.DedicatedCoreQuota)"
Write-Output "Low Priority Core Quota: $($BatchAccount.LowPriorityCoreQuota)"
if ($BatchAccount.AutoStorageAccountId) {
    $StorageAccountName = $BatchAccount.AutoStorageAccountId.Split('/')[-1]
    Write-Output "Auto Storage Account: $StorageAccountName"
}
try {
    $BatchContext = Get-AzBatchAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
    Write-Output "`nBatch Pools:"
    $Pools = Get-AzBatchPool -BatchContext $BatchContext
    if ($Pools.Count -eq 0) {
        Write-Output "No pools configured"
    } else {
        foreach ($Pool in $Pools) {
            Write-Output "  - Pool: $($Pool.Id)"
            Write-Output "    State: $($Pool.State)"
            Write-Output "    VM Size: $($Pool.VmSize)"
            Write-Output "    Target Dedicated Nodes: $($Pool.TargetDedicatedComputeNodes)"
            Write-Output "    Current Dedicated Nodes: $($Pool.CurrentDedicatedComputeNodes)"
            Write-Output "    Target Low Priority Nodes: $($Pool.TargetLowPriorityComputeNodes)"
            Write-Output "    Current Low Priority Nodes: $($Pool.CurrentLowPriorityComputeNodes)"
            Write-Output "    Auto Scale Enabled: $($Pool.EnableAutoScale)"
            Write-Output "    ---"
        }
    }
    Write-Output "`nBatch Jobs:"
    $Jobs = Get-AzBatchJob -BatchContext $BatchContext
    if ($Jobs.Count -eq 0) {
        Write-Output "No active jobs"
    } else {
        foreach ($Job in $Jobs) {
            Write-Output "  - Job: $($Job.Id)"
            Write-Output "    State: $($Job.State)"
            Write-Output "    Pool: $($Job.PoolInformation.PoolId)"
            Write-Output "    Priority: $($Job.Priority)"
            Write-Output "    Creation Time: $($Job.CreationTime)"
            $TaskCounts = Get-AzBatchTaskCount -JobId $Job.Id -BatchContext $BatchContext -ErrorAction SilentlyContinue
            if ($TaskCounts) {
                Write-Output "    Active Tasks: $($TaskCounts.Active)"
                Write-Output "    Running Tasks: $($TaskCounts.Running)"
                Write-Output "    Completed Tasks: $($TaskCounts.Completed)"
                Write-Output "    Failed Tasks: $($TaskCounts.Failed)"
            }
            Write-Output "    ---"
        }
    }
} catch {
    Write-Output "`n pool and job information: Unable to retrieve (check permissions)"
    Write-Output "Error: $($_.Exception.Message)"
}
Write-Output "`nQuota Information:"
Write-Output "Dedicated Core Quota: $($BatchAccount.DedicatedCoreQuota)"
Write-Output "Low Priority Core Quota: $($BatchAccount.LowPriorityCoreQuota)"
Write-Output "Pool Quota: $($BatchAccount.PoolQuota)"
Write-Output "Active Job and Job Schedule Quota: $($BatchAccount.ActiveJobAndJobScheduleQuota)"
Write-Output "`nBatch Account URLs:"
Write-Output "Portal: https://portal.azure.com/#@/resource$($BatchAccount.Id)"
Write-Output "Batch Explorer: https://azure.github.io/BatchExplorer/"
Write-Output "`nNext Steps for Optimization:"
Write-Output "1. Review pool utilization and scale settings"
Write-Output "2. Monitor job completion times and failure rates"
Write-Output "3. Optimize task distribution across nodes"
Write-Output "4. Consider using low-priority VMs for cost savings"
Write-Output "5. Implement auto-scaling for dynamic workloads"
Write-Output "`nBatch Account monitoring completed at $(Get-Date)"



