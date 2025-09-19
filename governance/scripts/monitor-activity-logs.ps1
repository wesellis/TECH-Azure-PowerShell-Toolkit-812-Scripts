#Requires -Module Az.Monitor
#Requires -Module Az.Profile
#Requires -Version 5.1

<#
.SYNOPSIS
    Monitors Azure Activity Logs for specific events and security incidents

.DESCRIPTION
    Queries Azure Activity Logs for administrative activities, security events,
    and resource changes. Supports filtering by time range, resource groups,
    and specific operations with alert capabilities.

.PARAMETER StartTime
    Start time for log query (default: 24 hours ago)

.PARAMETER EndTime
    End time for log query (default: now)

.PARAMETER ResourceGroupName
    Filter by specific resource group

.PARAMETER ResourceName
    Filter by specific resource name

.PARAMETER OperationName
    Filter by specific operation (e.g., Microsoft.Compute/virtualMachines/write)

.PARAMETER Level
    Log level filter: Critical, Error, Warning, Informational, Verbose

.PARAMETER Status
    Operation status: Started, Succeeded, Failed

.PARAMETER ExportPath
    Path to export results (CSV format)

.PARAMETER AlertEmail
    Email address for critical event alerts

.PARAMETER ShowSummary
    Display summary statistics

.PARAMETER ContinuousMonitoring
    Enable continuous monitoring mode

.PARAMETER MonitoringInterval
    Interval in seconds for continuous monitoring (default: 300)

.EXAMPLE
    .\monitor-activity-logs.ps1 -StartTime (Get-Date).AddHours(-1) -Level "Error"

    Monitor last hour for error-level events

.EXAMPLE
    .\monitor-activity-logs.ps1 -ResourceGroupName "RG-Production" -ShowSummary

    Monitor production resource group with summary

.NOTES
    Version: 1.0.0
    Created: 2024-11-15
#>

[CmdletBinding()]
param(
    [Parameter()]
    [DateTime]$StartTime = (Get-Date).AddDays(-1),

    [Parameter()]
    [DateTime]$EndTime = (Get-Date),

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$ResourceName,

    [Parameter()]
    [string]$OperationName,

    [Parameter()]
    [ValidateSet('Critical', 'Error', 'Warning', 'Informational', 'Verbose')]
    [string]$Level,

    [Parameter()]
    [ValidateSet('Started', 'Succeeded', 'Failed')]
    [string]$Status,

    [Parameter()]
    [string]$ExportPath,

    [Parameter()]
    [string]$AlertEmail,

    [Parameter()]
    [switch]$ShowSummary,

    [Parameter()]
    [switch]$ContinuousMonitoring,

    [Parameter()]
    [ValidateRange(60, 3600)]
    [int]$MonitoringInterval = 300
)

$ErrorActionPreference = 'Stop'

function Test-AzureConnection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-ActivityLogs {
    param(
        [DateTime]$Start,
        [DateTime]$End,
        [hashtable]$Filters
    )

    try {
        Write-Host "Querying activity logs from $($Start.ToString('yyyy-MM-dd HH:mm')) to $($End.ToString('yyyy-MM-dd HH:mm'))..." -ForegroundColor Yellow

        $params = @{
            StartTime = $Start
            EndTime = $End
        }

        # Add filters if specified
        if ($Filters.ResourceGroupName) {
            $params['ResourceGroupName'] = $Filters.ResourceGroupName
        }
        if ($Filters.ResourceName) {
            $params['ResourceName'] = $Filters.ResourceName
        }
        if ($Filters.OperationName) {
            $params['OperationName'] = $Filters.OperationName
        }

        $logs = Get-AzActivityLog @params

        # Apply additional filters
        if ($Filters.Level) {
            $logs = $logs | Where-Object { $_.Level -eq $Filters.Level }
        }
        if ($Filters.Status) {
            $logs = $logs | Where-Object { $_.Status -eq $Filters.Status }
        }

        return $logs | Sort-Object EventTimestamp -Descending
    }
    catch {
        Write-Error "Failed to retrieve activity logs: $_"
        return @()
    }
}

function Get-CriticalEvents {
    param([array]$Logs)

    $criticalPatterns = @(
        '*delete*',
        '*remove*',
        '*security*',
        '*policy*',
        '*role*',
        '*permission*',
        '*lock*',
        '*backup*'
    )

    $criticalEvents = @()

    foreach ($log in $Logs) {
        foreach ($pattern in $criticalPatterns) {
            if ($log.OperationName.Value -like $pattern -or
                $log.ResourceType.Value -like $pattern) {
                $criticalEvents += $log
                break
            }
        }

        # Check for failed critical operations
        if ($log.Status.Value -eq 'Failed' -and
            $log.Level -in @('Error', 'Critical')) {
            $criticalEvents += $log
        }
    }

    return $criticalEvents | Sort-Object EventTimestamp -Descending
}

function Show-LogSummary {
    param([array]$Logs)

    if ($Logs.Count -eq 0) {
        Write-Host "No activity logs found for the specified criteria" -ForegroundColor Yellow
        return
    }

    Write-Host "`nActivity Log Summary" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan

    # Overall statistics
    Write-Host "Total Events: $($Logs.Count)"
    Write-Host "Time Range: $($Logs[-1].EventTimestamp.ToString('yyyy-MM-dd HH:mm')) to $($Logs[0].EventTimestamp.ToString('yyyy-MM-dd HH:mm'))"

    # By level
    Write-Host "`nBy Level:" -ForegroundColor Cyan
    $Logs | Group-Object Level | Sort-Object Count -Descending | ForEach-Object {
        $color = switch ($_.Name) {
            'Critical' { 'Red' }
            'Error' { 'Red' }
            'Warning' { 'Yellow' }
            default { 'White' }
        }
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $color
    }

    # By status
    Write-Host "`nBy Status:" -ForegroundColor Cyan
    $Logs | Group-Object { $_.Status.Value } | Sort-Object Count -Descending | ForEach-Object {
        $color = switch ($_.Name) {
            'Failed' { 'Red' }
            'Succeeded' { 'Green' }
            default { 'White' }
        }
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $color
    }

    # Top operations
    Write-Host "`nTop Operations:" -ForegroundColor Cyan
    $Logs | Group-Object { $_.OperationName.Value } |
        Sort-Object Count -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count)"
        }

    # Resource groups
    if ($Logs | Where-Object { $_.ResourceGroupName }) {
        Write-Host "`nResource Groups:" -ForegroundColor Cyan
        $Logs | Where-Object { $_.ResourceGroupName } |
            Group-Object ResourceGroupName |
            Sort-Object Count -Descending |
            Select-Object -First 5 |
            ForEach-Object {
                Write-Host "  $($_.Name): $($_.Count)"
            }
    }
}

function Show-DetailedLogs {
    param([array]$Logs)

    if ($Logs.Count -eq 0) {
        return
    }

    Write-Host "`nDetailed Activity Logs" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan

    $displayLogs = $Logs | Select-Object -First 20 | ForEach-Object {
        [PSCustomObject]@{
            Time = $_.EventTimestamp.ToString('MM-dd HH:mm')
            Level = $_.Level
            Status = $_.Status.Value
            Operation = ($_.OperationName.Value -split '/')[-1]
            Resource = if ($_.ResourceId) { ($_.ResourceId -split '/')[-1] } else { 'N/A' }
            ResourceGroup = $_.ResourceGroupName
            Caller = $_.Caller
        }
    }

    $displayLogs | Format-Table -AutoSize

    if ($Logs.Count -gt 20) {
        Write-Host "... and $($Logs.Count - 20) more events" -ForegroundColor Yellow
    }
}

function Send-AlertEmail {
    param(
        [array]$CriticalEvents,
        [string]$EmailAddress
    )

    if ($CriticalEvents.Count -eq 0 -or -not $EmailAddress) {
        return
    }

    try {
        # This would require additional email configuration
        # For now, just display what would be sent
        Write-Host "`nWould send alert email to: $EmailAddress" -ForegroundColor Yellow
        Write-Host "Critical events detected: $($CriticalEvents.Count)" -ForegroundColor Red

        $CriticalEvents | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.EventTimestamp): $($_.OperationName.Value)" -ForegroundColor Red
        }
    }
    catch {
        Write-Warning "Failed to send alert email: $_"
    }
}

function Export-LogsToCSV {
    param(
        [array]$Logs,
        [string]$Path
    )

    if ($Logs.Count -eq 0) {
        Write-Warning "No logs to export"
        return
    }

    try {
        $exportData = $Logs | ForEach-Object {
            [PSCustomObject]@{
                EventTimestamp = $_.EventTimestamp
                Level = $_.Level
                Status = $_.Status.Value
                OperationName = $_.OperationName.Value
                ResourceId = $_.ResourceId
                ResourceGroupName = $_.ResourceGroupName
                ResourceType = $_.ResourceType.Value
                Caller = $_.Caller
                Description = $_.Description
                CorrelationId = $_.CorrelationId
            }
        }

        $exportData | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        Write-Host "Exported $($Logs.Count) events to: $Path" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export logs: $_"
    }
}

function Start-ContinuousMonitoring {
    param(
        [hashtable]$Filters,
        [int]$Interval,
        [string]$Email
    )

    Write-Host "`nStarting continuous monitoring (interval: $Interval seconds)" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow

    $lastCheckTime = Get-Date

    while ($true) {
        try {
            $currentTime = Get-Date
            $logs = Get-ActivityLogs -Start $lastCheckTime -End $currentTime -Filters $Filters

            if ($logs.Count -gt 0) {
                Write-Host "`n[$($currentTime.ToString('HH:mm:ss'))] Found $($logs.Count) new events" -ForegroundColor Green

                $criticalEvents = Get-CriticalEvents -Logs $logs
                if ($criticalEvents.Count -gt 0) {
                    Write-Host "CRITICAL: $($criticalEvents.Count) critical events detected!" -ForegroundColor Red
                    $criticalEvents | Select-Object -First 3 | ForEach-Object {
                        Write-Host "  - $($_.EventTimestamp.ToString('HH:mm')): $($_.OperationName.Value)" -ForegroundColor Red
                    }

                    if ($Email) {
                        Send-AlertEmail -CriticalEvents $criticalEvents -EmailAddress $Email
                    }
                }
            }

            $lastCheckTime = $currentTime
            Start-Sleep -Seconds $Interval
        }
        catch {
            Write-Warning "Monitoring error: $_"
            Start-Sleep -Seconds 60
        }
    }
}

# Main execution
Write-Host "`nAzure Activity Log Monitor" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

# Prepare filters
$filters = @{}
if ($ResourceGroupName) { $filters['ResourceGroupName'] = $ResourceGroupName }
if ($ResourceName) { $filters['ResourceName'] = $ResourceName }
if ($OperationName) { $filters['OperationName'] = $OperationName }
if ($Level) { $filters['Level'] = $Level }
if ($Status) { $filters['Status'] = $Status }

if ($ContinuousMonitoring) {
    Start-ContinuousMonitoring -Filters $filters -Interval $MonitoringInterval -Email $AlertEmail
}
else {
    # Single query mode
    $logs = Get-ActivityLogs -Start $StartTime -End $EndTime -Filters $filters

    if ($logs.Count -eq 0) {
        Write-Host "No activity logs found for the specified criteria" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Retrieved $($logs.Count) activity log entries" -ForegroundColor Green

    # Check for critical events
    $criticalEvents = Get-CriticalEvents -Logs $logs
    if ($criticalEvents.Count -gt 0) {
        Write-Host "`nCRITICAL EVENTS DETECTED: $($criticalEvents.Count)" -ForegroundColor Red
        $criticalEvents | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.EventTimestamp): $($_.OperationName.Value)" -ForegroundColor Red
        }

        if ($AlertEmail) {
            Send-AlertEmail -CriticalEvents $criticalEvents -EmailAddress $AlertEmail
        }
    }

    # Show summary if requested
    if ($ShowSummary) {
        Show-LogSummary -Logs $logs
    }

    # Show detailed logs
    Show-DetailedLogs -Logs $logs

    # Export if requested
    if ($ExportPath) {
        Export-LogsToCSV -Logs $logs -Path $ExportPath
    }

    Write-Host "`nMonitoring completed!" -ForegroundColor Green
}