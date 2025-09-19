#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Activity Log Checker

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
    We Enhanced Azure Activity Log Checker

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
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [int]$WEHoursBack = 24,
    
    [Parameter(Mandatory=$false)]
    [int]$WEMaxEvents = 20
)

#region Functions

Write-Information -Object " Retrieving Activity Log events (last $WEHoursBack hours)"

$WEStartTime = (Get-Date).AddHours(-$WEHoursBack)
$WEEndTime = Get-Date -ErrorAction Stop

if ($WEResourceGroupName) {
    $WEActivityLogs = Get-AzActivityLog -ResourceGroupName $WEResourceGroupName -StartTime $WEStartTime -EndTime $WEEndTime
    Write-Information -Object " Resource Group: $WEResourceGroupName"
} else {
   ;  $WEActivityLogs = Get-AzActivityLog -StartTime $WEStartTime -EndTime $WEEndTime
    Write-Information -Object " Subscription-wide activity"
}
; 
$WERecentLogs = $WEActivityLogs | Sort-Object EventTimestamp -Descending | Select-Object -First $WEMaxEvents

Write-Information -Object " `nRecent Activity (Last $WEMaxEvents events):"
Write-Information -Object (" =" * 60)

foreach ($WELog in $WERecentLogs) {
    Write-Information -Object " Time: $($WELog.EventTimestamp)"
    Write-Information -Object " Operation: $($WELog.OperationName.Value)"
    Write-Information -Object " Status: $($WELog.Status.Value)"
    Write-Information -Object " Resource: $($WELog.ResourceId.Split('/')[-1])"
    Write-Information -Object " Caller: $($WELog.Caller)"
    Write-Information -Object (" -" * 40)
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
