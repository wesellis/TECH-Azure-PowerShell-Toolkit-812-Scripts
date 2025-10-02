#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Retrieves and manages logs from Azure Container Instances

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
     log retrieval tool for Azure Container Instances with filtering,
    export capabilities, and real-time monitoring. Supports both single container
    and container group operations with  output options.
.PARAMETER ResourceGroupName
    Name of the resource group containing the container instance
.PARAMETER ContainerGroupName
    Name of the container group
.PARAMETER ContainerName
    Specific container name (optional - retrieves all if not specified)
.PARAMETER Tail
    Number of recent log lines to retrieve (default: 100)
.PARAMETER Follow
    Follow log output in real-time (like tail -f)
.PARAMETER Since
    Retrieve logs since a specific time (e.g., "2h", "30m", "1d")
.PARAMETER ExportPath
    Path to export logs to a file
.PARAMETER FilterPattern
    Filter logs by pattern (regex supported)
.PARAMETER ShowTimestamps
    Include timestamps in log output
.PARAMETER ShowMetadata
    Include container metadata with logs
.PARAMETER Format
    Output format: Text, JSON, CSV
    .\Azure-ContainerInstance-Logs.ps1 -ResourceGroupName "RG-Containers" -ContainerGroupName "web-app"
    Retrieves recent logs from all containers in the group
    .\Azure-ContainerInstance-Logs.ps1 -ResourceGroupName "RG-Containers" -ContainerGroupName "web-app" -ContainerName "frontend" -Tail 500
    Retrieves last 500 log lines from specific container
    .\Azure-ContainerInstance-Logs.ps1 -ResourceGroupName "RG-Containers" -ContainerGroupName "web-app" -Follow
    Follow logs in real-time
    .\Azure-ContainerInstance-Logs.ps1 -ResourceGroupName "RG-Containers" -ContainerGroupName "web-app" -ExportPath ".\logs.txt" -FilterPattern "ERROR"
    Export error logs to file
.NOTES
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerGroupName,
    [Parameter(ValueFromPipeline)]`n    [string]$ContainerName,
    [Parameter()]
    [int]$Tail = 100,
    [Parameter()]
    [switch]$Follow,
    [Parameter(ValueFromPipeline)]`n    [string]$Since,
    [Parameter(ValueFromPipeline)]`n    [string]$ExportPath,
    [Parameter(ValueFromPipeline)]`n    [string]$FilterPattern,
    [Parameter()]
    [switch]$ShowTimestamps,
    [Parameter()]
    [switch]$ShowMetadata,
    [Parameter()]
    [ValidateSet('Text', 'JSON', 'CSV')]
    [string]$Format = 'Text'
)
    [string]$ErrorActionPreference = 'Stop'
function (Get-AzContext) {
    try {
    $context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Green
            Connect-AzAccount
        }
        return $true
    }
    catch {
        Write-Error "Failed to establish Azure connection: $_"
        return $false
    }
}
function Write-Log {
    param(
        [string]$ResourceGroup,
        [string]$GroupName
    )
    try {
        Write-Host "Retrieving container group information..." -ForegroundColor Green
    $ContainerGroup = Get-AzContainerGroup -ResourceGroupName $ResourceGroup -Name $GroupName
        Write-Host "`nContainer Group Information:" -ForegroundColor Green
        Write-Output "Name: $($ContainerGroup.Name)"
        Write-Output "Location: $($ContainerGroup.Location)"
        Write-Output "State: $($ContainerGroup.State)" -ForegroundColor $(if ($ContainerGroup.State -eq 'Running') { 'Green' } else { 'Yellow' })
        Write-Output "OS Type: $($ContainerGroup.OsType)"
        if ($ContainerGroup.Container) {
            Write-Host "`nContainers:" -ForegroundColor Green
            foreach ($container in $ContainerGroup.Container) {
    [string]$status = if ($container.InstanceView) { $container.InstanceView.CurrentState.State } else { "Unknown" }
                Write-Output "  - $($container.Name): $status" -ForegroundColor $(if ($status -eq 'Running') { 'Green' } else { 'Yellow' })
            }
        }
        return $ContainerGroup
    }
    catch {
        throw "Failed to retrieve container group information: $_"
    }
}
function Get-ContainerLogs {
    param(
        [string]$ResourceGroup,
        [string]$GroupName,
        [string]$ContainerName,
        [int]$TailLines,
        [string]$SinceTime
    )
    try {
    $params = @{
            ResourceGroupName = $ResourceGroup
            ContainerGroupName = $GroupName
            Tail = $TailLines
        }
        if ($ContainerName) {
    [string]$params.ContainerName = $ContainerName
        }
    $logs = Get-AzContainerInstanceLog @params
        return $logs
    }
    catch {
        throw "Failed to retrieve container logs: $_"
    }
}
function Format-LogOutput {
    param(
        [string]$LogContent,
        [string]$ContainerName,
        [string]$OutputFormat,
        [bool]$IncludeTimestamps,
        [string]$FilterPattern
    )
    if (-not $LogContent) {
        return $null
    }
    [string]$LogLines = $LogContent -split "`n"
    if ($FilterPattern) {
    [string]$LogLines = $LogLines | Where-Object { $_ -match $FilterPattern }
    }
    switch ($OutputFormat) {
        'JSON' {
    [string]$JsonLogs = @()
    [string]$LineNumber = 1
            foreach ($line in $LogLines) {
                if ($line.Trim()) {
    $LogEntry = @{
                        LineNumber = $LineNumber
                        Container = $ContainerName
                        Timestamp = if ($IncludeTimestamps) { Get-Date } else { $null }
                        Message = $line.Trim()
                    }
    [string]$JsonLogs += $LogEntry
    [string]$LineNumber++
                }
            }
            return ($JsonLogs | ConvertTo-Json -Depth 2)
        }
        'CSV' {
    [string]$CsvLogs = @()
    [string]$LineNumber = 1
            foreach ($line in $LogLines) {
                if ($line.Trim()) {
    [string]$CsvLogs += [PSCustomObject]@{
                        LineNumber = $LineNumber
                        Container = $ContainerName
                        Timestamp = if ($IncludeTimestamps) { Get-Date } else { "" }
                        Message = $line.Trim()
                    }
    [string]$LineNumber++
                }
            }
            return ($CsvLogs | ConvertTo-Csv -NoTypeInformation)
        }
        default {
    [string]$FormattedLines = @()
            foreach ($line in $LogLines) {
                if ($line.Trim()) {
    [string]$prefix = ""
                    if ($IncludeTimestamps) {
    [string]$prefix += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] "
                    }
                    if ($ContainerName) {
    [string]$prefix += "[$ContainerName] "
                    }
    [string]$FormattedLines += "$prefix$($line.Trim())"
                }
            }
            return $FormattedLines -join "`n"
        }
    }
}
function Export-LogsToFile {
    param(
        [string]$Content,
        [string]$FilePath
    )
    try {
    [string]$directory = Split-Path $FilePath -Parent
        if ($directory -and -not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
    [string]$Content | Out-File -FilePath $FilePath -Encoding UTF8
        Write-Host "Logs exported to: $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export logs to file: $_"
    }
}
function Start-LogFollowing {
    param(
        [string]$ResourceGroup,
        [string]$GroupName,
        [string]$ContainerName,
        [string]$FilterPattern
    )
    Write-Host "Following logs in real-time. Press Ctrl+C to stop..." -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Cyan
    [string]$LastLogCount = 0
    try {
        while ($true) {
    $logs = Get-ContainerLogs -ResourceGroup $ResourceGroup -GroupName $GroupName -ContainerName $ContainerName -TailLines 1000
            if ($logs) {
    [string]$LogLines = $logs -split "`n"
    [string]$NewLogCount = $LogLines.Count
                if ($NewLogCount -gt $LastLogCount) {
    [string]$NewLines = $LogLines[$LastLogCount..($NewLogCount - 1)]
                    foreach ($line in $NewLines) {
                        if ($line.Trim()) {
    [string]$ShouldDisplay = $true
                            if ($FilterPattern -and $line -notmatch $FilterPattern) {
    [string]$ShouldDisplay = $false
                            }
                            if ($ShouldDisplay) {
    $timestamp = Get-Date -Format 'HH:mm:ss'
    [string]$prefix = if ($ContainerName) { "[$timestamp][$ContainerName] " } else { "[$timestamp] " }
                                Write-Host "$prefix$($line.Trim())" -ForegroundColor Green
                            }
                        }
                    }
    [string]$LastLogCount = $NewLogCount
                }
            }
            Start-Sleep -Seconds 2

} catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host "`nLog following stopped by user." -ForegroundColor Green
    }
    catch {
        Write-Error "Error during log following: $_"
    }
}
function Show-LogSummary {
    param(
        [string]$LogContent,
        [string]$ContainerName
    )
    if (-not $LogContent) {
        Write-Host "No logs available" -ForegroundColor Green
        return
    }
    [string]$LogLines = ($LogContent -split "`n") | Where-Object { $_.Trim() }
    [string]$TotalLines = $LogLines.Count
    Write-Host "`nLog Summary:" -ForegroundColor Green
    Write-Output "Container: $(if ($ContainerName) { $ContainerName } else { 'All containers' })"
    Write-Output "Total Lines: $TotalLines"
    Write-Host "Retrieved: $(Get-Date)" -ForegroundColor Green
    [string]$ErrorCount = ($LogLines | Where-Object { $_ -match "ERROR|Error|error" }).Count
    [string]$WarningCount = ($LogLines | Where-Object { $_ -match "WARN|Warning|warning" }).Count
    [string]$InfoCount = ($LogLines | Where-Object { $_ -match "INFO|Info|info" }).Count
    if ($ErrorCount -gt 0 -or $WarningCount -gt 0) {
        Write-Host "`nLog Level Breakdown:" -ForegroundColor Green
        if ($ErrorCount -gt 0) { Write-Host "Errors: $ErrorCount" -ForegroundColor Green
        if ($WarningCount -gt 0) { Write-Host "Warnings: $WarningCount" -ForegroundColor Green
        if ($InfoCount -gt 0) { Write-Host "Info: $InfoCount" -ForegroundColor Green
    }
}
Write-Host "`nAzure Container Instance Log Viewer" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
if (-not ((Get-AzContext))) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
try {
    $ContainerGroup = Get-ContainerGroupInfo -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName
    if ($ContainerName) {
    [string]$SpecificContainer = $ContainerGroup.Container | Where-Object { $_.Name -eq $ContainerName }
        if (-not $SpecificContainer) {
    [string]$AvailableContainers = ($ContainerGroup.Container | ForEach-Object { $_.Name }) -join ", "
            Write-Error "Container '$ContainerName' not found. Available containers: $AvailableContainers"
            throw
        }

} catch {
    Write-Error "Container group '$ContainerGroupName' not found in resource group '$ResourceGroupName': $_"
    throw
}
if ($Follow) {
    Start-LogFollowing -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName -ContainerName $ContainerName -FilterPattern $FilterPattern
    exit 0
}
Write-Host "`nRetrieving logs..." -ForegroundColor Green
try {
    if ($ContainerName) {
        Write-Host "Container: $ContainerName | Lines: $Tail" -ForegroundColor Green
    $logs = Get-ContainerLogs -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName -ContainerName $ContainerName -TailLines $Tail
    [string]$FormattedLogs = Format-LogOutput -LogContent $logs -ContainerName $ContainerName -OutputFormat $Format -IncludeTimestamps $ShowTimestamps -FilterPattern $FilterPattern
        if ($ShowMetadata) {
            Show-LogSummary -LogContent $logs -ContainerName $ContainerName
        }
        if ($FormattedLogs) {
            Write-Host "`nLogs:" -ForegroundColor Green
            Write-Output $FormattedLogs
            if ($ExportPath) {
                Export-LogsToFile -Content $FormattedLogs -FilePath $ExportPath
            }
        }
        else {
            Write-Host "No logs match the specified criteria" -ForegroundColor Green
        }
    }
    else {
        foreach ($container in $ContainerGroup.Container) {
            Write-Host "`n$("=" * 20) $($container.Name) $("=" * 20)" -ForegroundColor Green
    $logs = Get-ContainerLogs -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName -ContainerName $container.Name -TailLines $Tail
    [string]$FormattedLogs = Format-LogOutput -LogContent $logs -ContainerName $container.Name -OutputFormat $Format -IncludeTimestamps $ShowTimestamps -FilterPattern $FilterPattern
            if ($ShowMetadata) {
                Show-LogSummary -LogContent $logs -ContainerName $container.Name
            }
            if ($FormattedLogs) {
                Write-Output $FormattedLogs
                if ($ExportPath) {
    [string]$ContainerLogPath = $ExportPath -replace '(\.[^.]+)$', "_$($container.Name)`$1"
                    Export-LogsToFile -Content $FormattedLogs -FilePath $ContainerLogPath
                }
            }
            else {
                Write-Host "No logs available for this container" -ForegroundColor Green
            }
        }
    }
    Write-Host "`nLog retrieval completed!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to retrieve logs: $_"
    throw`n}
