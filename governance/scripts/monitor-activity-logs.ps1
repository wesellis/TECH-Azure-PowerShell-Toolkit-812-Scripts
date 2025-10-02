#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    monitor activity logs
.DESCRIPTION
    monitor activity logs operation
    Author: Wes Ellis (wes@wesellis.com)

    Monitors Azure Activity Logs for specific events and security incidents

    Queries Azure Activity Logs for administrative activities, security events,
    and resource changes. Supports filtering by time range, resource groups,
    and specific operations with alert capabilities.
.parameter StartTime
    Start time for log query (default: 24 hours ago)
.parameter EndTime
    End time for log query (default: now)
.parameter ResourceGroupName
    Filter by specific resource group
.parameter ResourceName
    Filter by specific resource name
.parameter OperationName
    Filter by specific operation (e.g., Microsoft.Compute/virtualMachines/write)
.parameter Level
    Log level filter: Critical, Error, Warning, Informational, Verbose
.parameter Status
    Operation status: Started, Succeeded, Failed
.parameter ExportPath
    Path to export results (CSV format)
.parameter AlertEmail
    Email address for critical event alerts
.parameter ShowSummary
    Display summary statistics
.parameter ContinuousMonitoring
    Enable continuous monitoring mode
.parameter MonitoringInterval
    Interval in seconds for continuous monitoring (default: 300)

    .\monitor-activity-logs.ps1 -StartTime (Get-Date).AddHours(-1) -Level "Error"

    Monitor last hour for error-level events

    .\monitor-activity-logs.ps1 -ResourceGroupName "RG-Production" -ShowSummary

    Monitor production resource group with summary

[CmdletBinding()]
param(
    [parameter()]
    [DateTime]$StartTime = (Get-Date).AddDays(-1),

    [parameter()]
    [DateTime]$EndTime = (Get-Date),

    [parameter(ValueFromPipeline)]`n    [string]$ResourceGroupName,

    [parameter(ValueFromPipeline)]`n    [string]$ResourceName,

    [parameter(ValueFromPipeline)]`n    [string]$OperationName,

    [parameter()]
    [ValidateSet('Critical', 'Error', 'Warning', 'Informational', 'Verbose')]
    [string]$Level,

    [parameter()]
    [ValidateSet('Started', 'Succeeded', 'Failed')]
    [string]$Status,

    [parameter(ValueFromPipeline)]`n    [string]$ExportPath,

    [parameter(ValueFromPipeline)]`n    [string]$AlertEmail,

    [parameter()]
    [switch]$ShowSummary,

    [parameter()]
    [switch]$ContinuousMonitoring,

    [parameter()]
    [ValidateRange(60, 3600)]
    [int]$MonitoringInterval = 300
)
    [string]$ErrorActionPreference = 'Stop'

function Write-Log {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
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
        Write-Host "Querying activity logs from $($Start.ToString('yyyy-MM-dd HH:mm')) to $($End.ToString('yyyy-MM-dd HH:mm'))..." -ForegroundColor Green
    $params = @{
            StartTime = $Start
            EndTime = $End
        }

        if ($Filters.ResourceGroupName) {
    [string]$params['ResourceGroupName'] = $Filters.ResourceGroupName
        }
        if ($Filters.ResourceName) {
    [string]$params['ResourceName'] = $Filters.ResourceName
        }
        if ($Filters.OperationName) {
    [string]$params['OperationName'] = $Filters.OperationName
        }
    $logs = Get-AzActivityLog @params

        if ($Filters.Level) {
    [string]$logs = $logs | Where-Object { $_.Level -eq $Filters.Level }
        }
        if ($Filters.Status) {
    [string]$logs = $logs | Where-Object { $_.Status -eq $Filters.Status }
        }

        return $logs | Sort-Object EventTimestamp -Descending
    }
    catch {
        write-Error "Failed to retrieve activity logs: $_"
        return @()
    }
}

function Get-CriticalEvents {
        param([array]$Logs)
    [string]$CriticalPatterns = @(
        '*delete*',
        '*remove*',
        '*security*',
        '*policy*',
        '*role*',
        '*permission*',
        '*lock*',
        '*backup*'
    )
    [string]$CriticalEvents = @()

    foreach ($log in $Logs) {
        foreach ($pattern in $CriticalPatterns) {
            if ($log.OperationName.Value -like $pattern -or
    [string]$log.ResourceType.Value -like $pattern) {
    [string]$CriticalEvents += $log
                break
            }
        }

        if ($log.Status.Value -eq 'Failed' -and
    [string]$log.Level -in @('Error', 'Critical')) {
    [string]$CriticalEvents += $log
        }
    }

    return $CriticalEvents | Sort-Object EventTimestamp -Descending
}

function Show-LogSummary {
        param([array]$Logs)

    if ($Logs.Count -eq 0) {
        Write-Host "No activity logs found for the specified criteria" -ForegroundColor Green
        return
    }

    Write-Host "`nActivity Log Summary" -ForegroundColor Green
    write-Host ("=" * 50) -ForegroundColor Cyan

    Write-Output "Total Events: $($Logs.Count)"
    Write-Output "Time Range: $($Logs[-1].EventTimestamp.ToString('yyyy-MM-dd HH:mm')) to $($Logs[0].EventTimestamp.ToString('yyyy-MM-dd HH:mm'))"

    Write-Host "`nBy Level:" -ForegroundColor Green
    [string]$Logs | Group-Object Level | Sort-Object Count -Descending | ForEach-Object {
    [string]$color = switch ($_.Name) {
            'Critical' { 'Red' }
            'Error' { 'Red' }
            'Warning' { 'Yellow' }
            default { 'White' }
        }
        Write-Output "  $($_.Name): $($_.Count)" -ForegroundColor $color
    }

    Write-Host "`nBy Status:" -ForegroundColor Green
    [string]$Logs | Group-Object { $_.Status.Value } | Sort-Object Count -Descending | ForEach-Object {
    [string]$color = switch ($_.Name) {
            'Failed' { 'Red' }
            'Succeeded' { 'Green' }
            default { 'White' }
        }
        Write-Output "  $($_.Name): $($_.Count)" -ForegroundColor $color
    }

    Write-Host "`nTop Operations:" -ForegroundColor Green
    [string]$Logs | Group-Object { $_.OperationName.Value } |
        Sort-Object Count -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            Write-Output "  $($_.Name): $($_.Count)"
        }

    if ($Logs | Where-Object { $_.ResourceGroupName }) {
        Write-Host "`nResource Groups:" -ForegroundColor Green
    [string]$Logs | Where-Object { $_.ResourceGroupName } |
            Group-Object ResourceGroupName |
            Sort-Object Count -Descending |
            Select-Object -First 5 |
            ForEach-Object {
                Write-Output "  $($_.Name): $($_.Count)"
            }
    }
}

function Show-DetailedLogs {
        param([array]$Logs)

    if ($Logs.Count -eq 0) {
        return
    }

    Write-Host "`nDetailed Activity Logs" -ForegroundColor Green
    write-Host ("=" * 50) -ForegroundColor Cyan
    [string]$DisplayLogs = $Logs | Select-Object -First 20 | ForEach-Object {
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
    [string]$DisplayLogs | Format-Table -AutoSize

    if ($Logs.Count -gt 20) {
        Write-Host "... and $($Logs.Count - 20) more events" -ForegroundColor Green
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
        Write-Host "`nWould send alert email to: $EmailAddress" -ForegroundColor Green
        Write-Host "Critical events detected: $($CriticalEvents.Count)" -ForegroundColor Green
    [string]$CriticalEvents | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.EventTimestamp): $($_.OperationName.Value)" -ForegroundColor Green

} catch {
        write-Warning "Failed to send alert email: $_"
    }
}

function Export-LogsToCSV {
        param(
        [array]$Logs,
        [string]$Path
    )

    if ($Logs.Count -eq 0) {
        write-Warning "No logs to export"
        return
    }

    try {
    [string]$ExportData = $Logs | ForEach-Object {
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
    [string]$ExportData | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        Write-Host "Exported $($Logs.Count) events to: $Path" -ForegroundColor Green
    }
    catch {
        write-Error "Failed to export logs: $_"
    }
}

function Start-ContinuousMonitoring {
        param(
        [hashtable]$Filters,
        [int]$Interval,
        [string]$Email
    )

    Write-Host "`nStarting continuous monitoring (interval: $Interval seconds)" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Green
    $LastCheckTime = Get-Date

    while ($true) {
        try {
    $CurrentTime = Get-Date
    $logs = Get-ActivityLogs -Start $LastCheckTime -End $CurrentTime -Filters $Filters

            if ($logs.Count -gt 0) {
                Write-Host "`n[$($CurrentTime.ToString('HH:mm:ss'))] Found $($logs.Count) new events" -ForegroundColor Green
    $CriticalEvents = Get-CriticalEvents -Logs $logs
                if ($CriticalEvents.Count -gt 0) {
                    Write-Host "CRITICAL: $($CriticalEvents.Count) critical events detected!" -ForegroundColor Green
    [string]$CriticalEvents | Select-Object -First 3 | ForEach-Object {
                        Write-Host "  - $($_.EventTimestamp.ToString('HH:mm')): $($_.OperationName.Value)" -ForegroundColor Green
                    }

                    if ($Email) {
                        Send-AlertEmail -CriticalEvents $CriticalEvents -EmailAddress $Email
                    }
                }
            }
    [string]$LastCheckTime = $CurrentTime
            Start-Sleep -Seconds $Interval
        }
        catch {
            write-Warning "Monitoring error: $_"
            Start-Sleep -Seconds 60
        }
    }
}

Write-Host "`nAzure Activity Log Monitor" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan
    [string]$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green
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
    $logs = Get-ActivityLogs -Start $StartTime -End $EndTime -Filters $filters

    if ($logs.Count -eq 0) {
        Write-Host "No activity logs found for the specified criteria" -ForegroundColor Green
        exit 0
    }

    Write-Host "Retrieved $($logs.Count) activity log entries" -ForegroundColor Green
    $CriticalEvents = Get-CriticalEvents -Logs $logs
    if ($CriticalEvents.Count -gt 0) {
        Write-Host "`nCRITICAL EVENTS DETECTED: $($CriticalEvents.Count)" -ForegroundColor Green
    [string]$CriticalEvents | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.EventTimestamp): $($_.OperationName.Value)" -ForegroundColor Green
        }

        if ($AlertEmail) {
            Send-AlertEmail -CriticalEvents $CriticalEvents -EmailAddress $AlertEmail
        }
    }

    if ($ShowSummary) {
        Show-LogSummary -Logs $logs
    }

    Show-DetailedLogs -Logs $logs

    if ($ExportPath) {
        Export-LogsToCSV -Logs $logs -Path $ExportPath
    }

    Write-Host "`nMonitoring completed!" -ForegroundColor Green
}\n



