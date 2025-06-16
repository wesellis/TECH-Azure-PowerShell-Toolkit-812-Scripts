# ============================================================================
# Script Name: Azure Activity Log Checker
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Retrieves recent Azure Activity Log events
# ============================================================================

param (
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [int]$HoursBack = 24,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxEvents = 20
)

Write-Host -Object "Retrieving Activity Log events (last $HoursBack hours)"

$StartTime = (Get-Date).AddHours(-$HoursBack)
$EndTime = Get-Date

if ($ResourceGroupName) {
    $ActivityLogs = Get-AzActivityLog -ResourceGroupName $ResourceGroupName -StartTime $StartTime -EndTime $EndTime
    Write-Host -Object "Resource Group: $ResourceGroupName"
} else {
    $ActivityLogs = Get-AzActivityLog -StartTime $StartTime -EndTime $EndTime
    Write-Host -Object "Subscription-wide activity"
}

$RecentLogs = $ActivityLogs | Sort-Object EventTimestamp -Descending | Select-Object -First $MaxEvents

Write-Host -Object "`nRecent Activity (Last $MaxEvents events):"
Write-Host -Object ("=" * 60)

foreach ($Log in $RecentLogs) {
    Write-Host -Object "Time: $($Log.EventTimestamp)"
    Write-Host -Object "Operation: $($Log.OperationName.Value)"
    Write-Host -Object "Status: $($Log.Status.Value)"
    Write-Host -Object "Resource: $($Log.ResourceId.Split('/')[-1])"
    Write-Host -Object "Caller: $($Log.Caller)"
    Write-Host -Object ("-" * 40)
}
