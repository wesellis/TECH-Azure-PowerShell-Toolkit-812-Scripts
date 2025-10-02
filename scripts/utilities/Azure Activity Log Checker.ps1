#Requires -Version 7.4
#Requires -Modules Az.Monitor

<#
.SYNOPSIS
    Azure Activity Log Checker

.DESCRIPTION
    Retrieves and displays Azure Activity Log events for monitoring and auditing purposes.
    Can filter by resource group or show subscription-wide activity.

.PARAMETER ResourceGroupName
    Optional resource group name to filter activity logs

.PARAMETER HoursBack
    Number of hours to look back for activity logs (default: 24)

.PARAMETER MaxEvents
    Maximum number of events to display (default: 20)

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateRange(1, 720)]
    [int]$HoursBack = 24,

    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$MaxEvents = 20
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $logEntry = "$timestamp [Activity-Log] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

try {
    Write-ColorOutput "Retrieving Activity Log events (last $HoursBack hours)" -Level INFO

    $startTime = (Get-Date).AddHours(-$HoursBack)
    $endTime = Get-Date

    # Build parameters for Get-AzActivityLog
    $activityLogParams = @{
        StartTime = $startTime
        EndTime = $endTime
        MaxRecord = 1000
    }

    if ($ResourceGroupName) {
        $activityLogParams['ResourceGroupName'] = $ResourceGroupName
        Write-ColorOutput "Filtering by Resource Group: $ResourceGroupName" -Level INFO
    } else {
        Write-ColorOutput "Retrieving subscription-wide activity" -Level INFO
    }

    # Get activity logs
    $activityLogs = Get-AzActivityLog @activityLogParams -ErrorAction Stop

    if ($activityLogs.Count -eq 0) {
        Write-ColorOutput "No activity logs found in the specified time range" -Level WARN
        return
    }

    # Sort and limit results
    $recentLogs = $activityLogs |
        Sort-Object EventTimestamp -Descending |
        Select-Object -First $MaxEvents

    Write-ColorOutput "`nRecent Activity (Last $MaxEvents events):" -Level SUCCESS
    Write-Host ("=" * 60) -ForegroundColor DarkGray

    foreach ($log in $recentLogs) {
        # Determine log level based on status
        $logLevel = switch ($log.Status.Value) {
            "Succeeded" { "SUCCESS" }
            "Failed" { "ERROR" }
            "Started" { "INFO" }
            default { "INFO" }
        }

        Write-Host "`nTime: $($log.EventTimestamp)" -ForegroundColor White
        Write-Host "Operation: $($log.OperationName.Value)" -ForegroundColor White

        $statusColor = switch ($log.Status.Value) {
            "Succeeded" { "Green" }
            "Failed" { "Red" }
            "Started" { "Yellow" }
            default { "Gray" }
        }
        Write-Host "Status: $($log.Status.Value)" -ForegroundColor $statusColor

        if ($log.ResourceId) {
            $resourceName = $log.ResourceId.Split('/')[-1]
            Write-Host "Resource: $resourceName" -ForegroundColor White
        }

        if ($log.Caller) {
            Write-Host "Caller: $($log.Caller)" -ForegroundColor White
        }

        if ($log.Level -and $log.Level -ne "Informational") {
            Write-Host "Level: $($log.Level)" -ForegroundColor Yellow
        }

        if ($log.Properties -and $log.Properties.statusMessage) {
            Write-Host "Message: $($log.Properties.statusMessage)" -ForegroundColor Gray
        }

        Write-Host ("-" * 40) -ForegroundColor DarkGray
    }

    # Summary statistics
    Write-Host "`nSummary Statistics:" -ForegroundColor Cyan
    Write-Host "Total events found: $($activityLogs.Count)" -ForegroundColor White

    $statusGroups = $activityLogs | Group-Object -Property { $_.Status.Value }
    foreach ($group in $statusGroups) {
        $color = switch ($group.Name) {
            "Succeeded" { "Green" }
            "Failed" { "Red" }
            "Started" { "Yellow" }
            default { "Gray" }
        }
        Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor $color
    }

    Write-ColorOutput "`nActivity log check completed" -Level SUCCESS
}
catch {
    Write-ColorOutput "Failed to retrieve activity logs: $($_.Exception.Message)" -Level ERROR
    throw
}