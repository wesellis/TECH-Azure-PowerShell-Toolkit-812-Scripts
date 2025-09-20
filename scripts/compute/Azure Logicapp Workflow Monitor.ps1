#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Logicapp Workflow Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,
    [int]$DaysBack = 7
)
Write-Host "Monitoring Logic App: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Analysis Period: Last $DaysBack days"
Write-Host " ============================================"
$LogicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Host "Logic App Information:"
Write-Host "Name: $($LogicApp.Name)"
Write-Host "State: $($LogicApp.State)"
Write-Host "Location: $($LogicApp.Location)"
Write-Host "Provisioning State: $($LogicApp.ProvisioningState)"
$EndTime = Get-Date -ErrorAction Stop
$StartTime = $EndTime.AddDays(-$DaysBack)
Write-Host " `nWorkflow Runs (Last $DaysBack days):"
try {
    $WorkflowRuns = Get-AzLogicAppRunHistory -ResourceGroupName $ResourceGroupName -Name $AppName
    $RecentRuns = $WorkflowRuns | Where-Object { $_.StartTime -ge $StartTime } | Sort-Object StartTime -Descending
    if ($RecentRuns.Count -eq 0) {
        Write-Host "No runs found in the specified period"
    } else {
        # Summary by status
        $RunSummary = $RecentRuns | Group-Object Status
        Write-Host " `nRun Summary:"
        foreach ($Group in $RunSummary) {
            Write-Host "  $($Group.Name): $($Group.Count) runs"
        }
        # Recent runs detail
        Write-Host " `nRecent Runs (Last 10):"
$LatestRuns = $RecentRuns | Select-Object -First 10
        foreach ($Run in $LatestRuns) {
            Write-Host "  - Run ID: $($Run.Name)"
            Write-Host "    Status: $($Run.Status)"
            Write-Host "    Start Time: $($Run.StartTime)"
            Write-Host "    End Time: $($Run.EndTime)"
            if ($Run.EndTime -and $Run.StartTime) {
$Duration = $Run.EndTime - $Run.StartTime
                Write-Host "    Duration: $($Duration.ToString('hh\:mm\:ss'))"
            }
            if ($Run.Error) {
                Write-Host "    Error: $($Run.Error.Message)"
            }
            Write-Host "    ---"
        }
    }
} catch {
    Write-Host "Unable to retrieve workflow runs: $($_.Exception.Message)"
}
Write-Host " `nLogic App Designer:"
Write-Host "Portal URL: https://portal.azure.com/#@/resource$($LogicApp.Id)/designer"
Write-Host " `nMonitoring completed at $(Get-Date)"


