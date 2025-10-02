#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Logicapp Workflow Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,
    [int]$DaysBack = 7
)
Write-Output "Monitoring Logic App: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Analysis Period: Last $DaysBack days"
Write-Output " ============================================"
$LogicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Output "Logic App Information:"
Write-Output "Name: $($LogicApp.Name)"
Write-Output "State: $($LogicApp.State)"
Write-Output "Location: $($LogicApp.Location)"
Write-Output "Provisioning State: $($LogicApp.ProvisioningState)"
$EndTime = Get-Date -ErrorAction Stop
    [string]$StartTime = $EndTime.AddDays(-$DaysBack)
Write-Output " `nWorkflow Runs (Last $DaysBack days):"
try {
$WorkflowRuns = Get-AzLogicAppRunHistory -ResourceGroupName $ResourceGroupName -Name $AppName
    [string]$RecentRuns = $WorkflowRuns | Where-Object { $_.StartTime -ge $StartTime } | Sort-Object StartTime -Descending
    if ($RecentRuns.Count -eq 0) {
        Write-Output "No runs found in the specified period"
    } else {
    [string]$RunSummary = $RecentRuns | Group-Object Status
        Write-Output " `nRun Summary:"
        foreach ($Group in $RunSummary) {
            Write-Output "  $($Group.Name): $($Group.Count) runs"
        }
        Write-Output " `nRecent Runs (Last 10):"
    [string]$LatestRuns = $RecentRuns | Select-Object -First 10
        foreach ($Run in $LatestRuns) {
            Write-Output "  - Run ID: $($Run.Name)"
            Write-Output "    Status: $($Run.Status)"
            Write-Output "    Start Time: $($Run.StartTime)"
            Write-Output "    End Time: $($Run.EndTime)"
            if ($Run.EndTime -and $Run.StartTime) {
    [string]$Duration = $Run.EndTime - $Run.StartTime
                Write-Output "    Duration: $($Duration.ToString('hh\:mm\:ss'))"
            }
            if ($Run.Error) {
                Write-Output "    Error: $($Run.Error.Message)"
            }
            Write-Output "    ---"
        }
    }
} catch {
    Write-Output "Unable to retrieve workflow runs: $($_.Exception.Message)"
}
Write-Output " `nLogic App Designer:"
Write-Output "Portal URL: https://portal.azure.com/#@/resource$($LogicApp.Id)/designer"
Write-Output " `nMonitoring completed at $(Get-Date)"



