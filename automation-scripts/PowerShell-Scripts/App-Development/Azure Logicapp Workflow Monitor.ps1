#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Logicapp Workflow Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Logicapp Workflow Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAppName,
    [int]$WEDaysBack = 7
)

#region Functions

Write-WELog " Monitoring Logic App: $WEAppName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Analysis Period: Last $WEDaysBack days" " INFO"
Write-WELog " ============================================" " INFO"


$WELogicApp = Get-AzLogicApp -ResourceGroupName $WEResourceGroupName -Name $WEAppName

Write-WELog " Logic App Information:" " INFO"
Write-WELog "  Name: $($WELogicApp.Name)" " INFO"
Write-WELog "  State: $($WELogicApp.State)" " INFO"
Write-WELog "  Location: $($WELogicApp.Location)" " INFO"
Write-WELog "  Provisioning State: $($WELogicApp.ProvisioningState)" " INFO"


$WEEndTime = Get-Date -ErrorAction Stop
$WEStartTime = $WEEndTime.AddDays(-$WEDaysBack)

Write-WELog " `nWorkflow Runs (Last $WEDaysBack days):" " INFO"
try {
    $WEWorkflowRuns = Get-AzLogicAppRunHistory -ResourceGroupName $WEResourceGroupName -Name $WEAppName
    
    $WERecentRuns = $WEWorkflowRuns | Where-Object { $_.StartTime -ge $WEStartTime } | Sort-Object StartTime -Descending
    
    if ($WERecentRuns.Count -eq 0) {
        Write-WELog "  No runs found in the specified period" " INFO"
    } else {
        # Summary by status
        $WERunSummary = $WERecentRuns | Group-Object Status
        Write-WELog " `nRun Summary:" " INFO"
        foreach ($WEGroup in $WERunSummary) {
            Write-WELog "  $($WEGroup.Name): $($WEGroup.Count) runs" " INFO"
        }
        
        # Recent runs detail
        Write-WELog " `nRecent Runs (Last 10):" " INFO"
       ;  $WELatestRuns = $WERecentRuns | Select-Object -First 10
        
        foreach ($WERun in $WELatestRuns) {
            Write-WELog "  - Run ID: $($WERun.Name)" " INFO"
            Write-WELog "    Status: $($WERun.Status)" " INFO"
            Write-WELog "    Start Time: $($WERun.StartTime)" " INFO"
            Write-WELog "    End Time: $($WERun.EndTime)" " INFO"
            
            if ($WERun.EndTime -and $WERun.StartTime) {
               ;  $WEDuration = $WERun.EndTime - $WERun.StartTime
                Write-WELog "    Duration: $($WEDuration.ToString('hh\:mm\:ss'))" " INFO"
            }
            
            if ($WERun.Error) {
                Write-WELog "    Error: $($WERun.Error.Message)" " INFO"
            }
            Write-WELog "    ---" " INFO"
        }
    }
} catch {
    Write-WELog "  Unable to retrieve workflow runs: $($_.Exception.Message)" " INFO"
}

Write-WELog " `nLogic App Designer:" " INFO"
Write-WELog " Portal URL: https://portal.azure.com/#@/resource$($WELogicApp.Id)/designer" " INFO"

Write-WELog " `nMonitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
