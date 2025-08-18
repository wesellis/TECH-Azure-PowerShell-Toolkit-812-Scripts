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

Write-Information -Object "Retrieving Activity Log events (last $HoursBack hours)"

$StartTime = (Get-Date).AddHours(-$HoursBack)
$EndTime = Get-Date -ErrorAction Stop

if ($ResourceGroupName) {
    $ActivityLogs = Get-AzActivityLog -ResourceGroupName $ResourceGroupName -StartTime $StartTime -EndTime $EndTime
    Write-Information -Object "Resource Group: $ResourceGroupName"
} else {
    $ActivityLogs = Get-AzActivityLog -StartTime $StartTime -EndTime $EndTime
    Write-Information -Object "Subscription-wide activity"
}

$RecentLogs = $ActivityLogs | Sort-Object EventTimestamp -Descending | Select-Object -First $MaxEvents

Write-Information -Object "`nRecent Activity (Last $MaxEvents events):"
Write-Information -Object ("=" * 60)

foreach ($Log in $RecentLogs) {
    Write-Information -Object "Time: $($Log.EventTimestamp)"
    Write-Information -Object "Operation: $($Log.OperationName.Value)"
    Write-Information -Object "Status: $($Log.Status.Value)"
    Write-Information -Object "Resource: $($Log.ResourceId.Split('/')[-1])"
    Write-Information -Object "Caller: $($Log.Caller)"
    Write-Information -Object ("-" * 40)
}
