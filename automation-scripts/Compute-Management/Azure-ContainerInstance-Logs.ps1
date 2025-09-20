<#
.SYNOPSIS
    Retrieves and manages logs from Azure Container Instances

.DESCRIPTION
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
.NOTES#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerGroupName,
    [Parameter()]
    [string]$ContainerName,
    [Parameter()]
    [int]$Tail = 100,
    [Parameter()]
    [switch]$Follow,
    [Parameter()]
    [string]$Since,
    [Parameter()]
    [string]$ExportPath,
    [Parameter()]
    [string]$FilterPattern,
    [Parameter()]
    [switch]$ShowTimestamps,
    [Parameter()]
    [switch]$ShowMetadata,
    [Parameter()]
    [ValidateSet('Text', 'JSON', 'CSV')]
    [string]$Format = 'Text'
)
$ErrorActionPreference = 'Stop'
function (Get-AzContext) {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Yellow
            Connect-AzAccount
        }
        return $true
    }
    catch {
        Write-Error "Failed to establish Azure connection: $_"
        return $false
    }
}
function Get-ContainerGroupInfo {
    param(
        [string]$ResourceGroup,
        [string]$GroupName
    )
    try {
        Write-Host "Retrieving container group information..." -ForegroundColor Yellow
        $containerGroup = Get-AzContainerGroup -ResourceGroupName $ResourceGroup -Name $GroupName
        Write-Host "`nContainer Group Information:" -ForegroundColor Cyan
        Write-Host "Name: $($containerGroup.Name)"
        Write-Host "Location: $($containerGroup.Location)"
        Write-Host "State: $($containerGroup.State)" -ForegroundColor $(if ($containerGroup.State -eq 'Running') { 'Green' } else { 'Yellow' })
        Write-Host "OS Type: $($containerGroup.OsType)"
        if ($containerGroup.Container) {
            Write-Host "`nContainers:" -ForegroundColor Cyan
            foreach ($container in $containerGroup.Container) {
                $status = if ($container.InstanceView) { $container.InstanceView.CurrentState.State } else { "Unknown" }
                Write-Host "  - $($container.Name): $status" -ForegroundColor $(if ($status -eq 'Running') { 'Green' } else { 'Yellow' })
            }
        }
        return $containerGroup
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
            $params.ContainerName = $ContainerName
        }
        # Note: Az.ContainerInstance module doesn't support Since parameter directly
        # This would need to be implemented with filtering after retrieval
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
    $logLines = $LogContent -split "`n"
    # Apply filter if specified
    if ($FilterPattern) {
        $logLines = $logLines | Where-Object { $_ -match $FilterPattern }
    }
    switch ($OutputFormat) {
        'JSON' {
            $jsonLogs = @()
            $lineNumber = 1
            foreach ($line in $logLines) {
                if ($line.Trim()) {
                    $logEntry = @{
                        LineNumber = $lineNumber
                        Container = $ContainerName
                        Timestamp = if ($IncludeTimestamps) { Get-Date } else { $null }
                        Message = $line.Trim()
                    }
                    $jsonLogs += $logEntry
                    $lineNumber++
                }
            }
            return ($jsonLogs | ConvertTo-Json -Depth 2)
        }
        'CSV' {
            $csvLogs = @()
            $lineNumber = 1
            foreach ($line in $logLines) {
                if ($line.Trim()) {
                    $csvLogs += [PSCustomObject]@{
                        LineNumber = $lineNumber
                        Container = $ContainerName
                        Timestamp = if ($IncludeTimestamps) { Get-Date } else { "" }
                        Message = $line.Trim()
                    }
                    $lineNumber++
                }
            }
            return ($csvLogs | ConvertTo-Csv -NoTypeInformation)
        }
        default {
            # Text format
            $formattedLines = @()
            foreach ($line in $logLines) {
                if ($line.Trim()) {
                    $prefix = ""
                    if ($IncludeTimestamps) {
                        $prefix += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] "
                    }
                    if ($ContainerName) {
                        $prefix += "[$ContainerName] "
                    }
                    $formattedLines += "$prefix$($line.Trim())"
                }
            }
            return $formattedLines -join "`n"
        }
    }
}
function Export-LogsToFile {
    param(
        [string]$Content,
        [string]$FilePath
    )
    try {
        $directory = Split-Path $FilePath -Parent
        if ($directory -and -not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        $Content | Out-File -FilePath $FilePath -Encoding UTF8
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
    Write-Host "Following logs in real-time. Press Ctrl+C to stop..." -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Cyan
    $lastLogCount = 0
    try {
        while ($true) {
            $logs = Get-ContainerLogs -ResourceGroup $ResourceGroup -GroupName $GroupName -ContainerName $ContainerName -TailLines 1000
            if ($logs) {
                $logLines = $logs -split "`n"
                $newLogCount = $logLines.Count
                if ($newLogCount -gt $lastLogCount) {
                    $newLines = $logLines[$lastLogCount..($newLogCount - 1)]
                    foreach ($line in $newLines) {
                        if ($line.Trim()) {
                            $shouldDisplay = $true
                            if ($FilterPattern -and $line -notmatch $FilterPattern) {
                                $shouldDisplay = $false
                            }
                            if ($shouldDisplay) {
                                $timestamp = Get-Date -Format 'HH:mm:ss'
                                $prefix = if ($ContainerName) { "[$timestamp][$ContainerName] " } else { "[$timestamp] " }
                                Write-Host "$prefix$($line.Trim())" -ForegroundColor White
                            }
                        }
                    }
                    $lastLogCount = $newLogCount
                }
            }
            Start-Sleep -Seconds 2
        
} catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host "`nLog following stopped by user." -ForegroundColor Yellow
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
        Write-Host "No logs available" -ForegroundColor Yellow
        return
    }
    $logLines = ($LogContent -split "`n") | Where-Object { $_.Trim() }
    $totalLines = $logLines.Count
    Write-Host "`nLog Summary:" -ForegroundColor Cyan
    Write-Host "Container: $(if ($ContainerName) { $ContainerName } else { 'All containers' })"
    Write-Host "Total Lines: $totalLines"
    Write-Host "Retrieved: $(Get-Date)" -ForegroundColor Gray
    # Simple pattern analysis
    $errorCount = ($logLines | Where-Object { $_ -match "ERROR|Error|error" }).Count
    $warningCount = ($logLines | Where-Object { $_ -match "WARN|Warning|warning" }).Count
    $infoCount = ($logLines | Where-Object { $_ -match "INFO|Info|info" }).Count
    if ($errorCount -gt 0 -or $warningCount -gt 0) {
        Write-Host "`nLog Level Breakdown:" -ForegroundColor Cyan
        if ($errorCount -gt 0) { Write-Host "Errors: $errorCount" -ForegroundColor Red }
        if ($warningCount -gt 0) { Write-Host "Warnings: $warningCount" -ForegroundColor Yellow }
        if ($infoCount -gt 0) { Write-Host "Info: $infoCount" -ForegroundColor Green }
    }
}
# Main execution
Write-Host "`nAzure Container Instance Log Viewer" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
# Test Azure connection
if (-not ((Get-AzContext))) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
# Get and validate container group
try {
    $containerGroup = Get-ContainerGroupInfo -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName
    # Validate specific container if specified
    if ($ContainerName) {
        $specificContainer = $containerGroup.Container | Where-Object { $_.Name -eq $ContainerName }
        if (-not $specificContainer) {
            $availableContainers = ($containerGroup.Container | ForEach-Object { $_.Name }) -join ", "
            Write-Error "Container '$ContainerName' not found. Available containers: $availableContainers"
            throw
        }
    
} catch {
    Write-Error "Container group '$ContainerGroupName' not found in resource group '$ResourceGroupName': $_"
    throw
}
# Handle follow mode
if ($Follow) {
    Start-LogFollowing -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName -ContainerName $ContainerName -FilterPattern $FilterPattern
    exit 0
}
# Retrieve logs
Write-Host "`nRetrieving logs..." -ForegroundColor Yellow
try {
    if ($ContainerName) {
        Write-Host "Container: $ContainerName | Lines: $Tail" -ForegroundColor Cyan
        $logs = Get-ContainerLogs -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName -ContainerName $ContainerName -TailLines $Tail
        $formattedLogs = Format-LogOutput -LogContent $logs -ContainerName $ContainerName -OutputFormat $Format -IncludeTimestamps $ShowTimestamps -FilterPattern $FilterPattern
        if ($ShowMetadata) {
            Show-LogSummary -LogContent $logs -ContainerName $ContainerName
        }
        if ($formattedLogs) {
            Write-Host "`nLogs:" -ForegroundColor Cyan
            Write-Host $formattedLogs
            if ($ExportPath) {
                Export-LogsToFile -Content $formattedLogs -FilePath $ExportPath
            }
        }
        else {
            Write-Host "No logs match the specified criteria" -ForegroundColor Yellow
        }
    }
    else {
        # Get logs from all containers
        foreach ($container in $containerGroup.Container) {
            Write-Host "`n$("=" * 20) $($container.Name) $("=" * 20)" -ForegroundColor Cyan
            $logs = Get-ContainerLogs -ResourceGroup $ResourceGroupName -GroupName $ContainerGroupName -ContainerName $container.Name -TailLines $Tail
            $formattedLogs = Format-LogOutput -LogContent $logs -ContainerName $container.Name -OutputFormat $Format -IncludeTimestamps $ShowTimestamps -FilterPattern $FilterPattern
            if ($ShowMetadata) {
                Show-LogSummary -LogContent $logs -ContainerName $container.Name
            }
            if ($formattedLogs) {
                Write-Host $formattedLogs
                if ($ExportPath) {
                    $containerLogPath = $ExportPath -replace '(\.[^.]+)$', "_$($container.Name)`$1"
                    Export-LogsToFile -Content $formattedLogs -FilePath $containerLogPath
                }
            }
            else {
                Write-Host "No logs available for this container" -ForegroundColor Yellow
            }
        }
    }
    Write-Host "`nLog retrieval completed!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to retrieve logs: $_"
    throw
}

