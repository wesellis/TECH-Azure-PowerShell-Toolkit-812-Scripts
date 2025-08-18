# ============================================================================
# Script Name: Azure Logic App Workflow Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Logic App workflows, runs, and trigger history
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AppName,
    [int]$DaysBack = 7
)

Write-Information "Monitoring Logic App: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Analysis Period: Last $DaysBack days"
Write-Information "============================================"

# Get Logic App details
$LogicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Information "Logic App Information:"
Write-Information "  Name: $($LogicApp.Name)"
Write-Information "  State: $($LogicApp.State)"
Write-Information "  Location: $($LogicApp.Location)"
Write-Information "  Provisioning State: $($LogicApp.ProvisioningState)"

# Get workflow runs
$EndTime = Get-Date -ErrorAction Stop
$StartTime = $EndTime.AddDays(-$DaysBack)

Write-Information "`nWorkflow Runs (Last $DaysBack days):"
try {
    $WorkflowRuns = Get-AzLogicAppRunHistory -ResourceGroupName $ResourceGroupName -Name $AppName
    
    $RecentRuns = $WorkflowRuns | Where-Object { $_.StartTime -ge $StartTime } | Sort-Object StartTime -Descending
    
    if ($RecentRuns.Count -eq 0) {
        Write-Information "  No runs found in the specified period"
    } else {
        # Summary by status
        $RunSummary = $RecentRuns | Group-Object Status
        Write-Information "`nRun Summary:"
        foreach ($Group in $RunSummary) {
            Write-Information "  $($Group.Name): $($Group.Count) runs"
        }
        
        # Recent runs detail
        Write-Information "`nRecent Runs (Last 10):"
        $LatestRuns = $RecentRuns | Select-Object -First 10
        
        foreach ($Run in $LatestRuns) {
            Write-Information "  - Run ID: $($Run.Name)"
            Write-Information "    Status: $($Run.Status)"
            Write-Information "    Start Time: $($Run.StartTime)"
            Write-Information "    End Time: $($Run.EndTime)"
            
            if ($Run.EndTime -and $Run.StartTime) {
                $Duration = $Run.EndTime - $Run.StartTime
                Write-Information "    Duration: $($Duration.ToString('hh\:mm\:ss'))"
            }
            
            if ($Run.Error) {
                Write-Information "    Error: $($Run.Error.Message)"
            }
            Write-Information "    ---"
        }
    }
} catch {
    Write-Information "  Unable to retrieve workflow runs: $($_.Exception.Message)"
}

Write-Information "`nLogic App Designer:"
Write-Information "Portal URL: https://portal.azure.com/#@/resource$($LogicApp.Id)/designer"

Write-Information "`nMonitoring completed at $(Get-Date)"
