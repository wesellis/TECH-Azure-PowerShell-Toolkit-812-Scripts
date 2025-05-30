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

Write-Host "Retrieving Activity Log events (last $HoursBack hours)"

$StartTime = (Get-Date).AddHours(-$HoursBack)
$EndTime = Get-Date

if ($ResourceGroupName) {
    $ActivityLogs = Get-AzActivityLog -ResourceGroupName $ResourceGroupName -StartTime $StartTime -EndTime $EndTime
    Write-Host "Resource Group: $ResourceGroupName"
} else {
    $ActivityLogs = Get-AzActivityLog -StartTime $StartTime -EndTime $EndTime
    Write-Host "Subscription-wide activity"
}

$RecentLogs = $ActivityLogs | Sort-Object EventTimestamp -Descending | Select-Object -First $MaxEvents

Write-Host "`nRecent Activity (Last $MaxEvents events):"
Write-Host "=" * 60

foreach ($Log in $RecentLogs) {
    Write-Host "Time: $($Log.EventTimestamp)"
    Write-Host "Operation: $($Log.OperationName.Value)"
    Write-Host "Status: $($Log.Status.Value)"
    Write-Host "Resource: $($Log.ResourceId.Split('/')[-1])"
    Write-Host "Caller: $($Log.Caller)"
    Write-Host "-" * 40
}
