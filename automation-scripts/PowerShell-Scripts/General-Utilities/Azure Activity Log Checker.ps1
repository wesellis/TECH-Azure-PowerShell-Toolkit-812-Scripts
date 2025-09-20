#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Activity Log Checker

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
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
    [int]$HoursBack = 24,
    [Parameter()]
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
Write-Information -Object " `nRecent Activity (Last $MaxEvents events):"
Write-Information -Object (" =" * 60)
foreach ($Log in $RecentLogs) {
    Write-Information -Object "Time: $($Log.EventTimestamp)"
    Write-Information -Object "Operation: $($Log.OperationName.Value)"
    Write-Information -Object "Status: $($Log.Status.Value)"
    Write-Information -Object "Resource: $($Log.ResourceId.Split('/')[-1])"
    Write-Information -Object "Caller: $($Log.Caller)"
    Write-Information -Object (" -" * 40)
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

