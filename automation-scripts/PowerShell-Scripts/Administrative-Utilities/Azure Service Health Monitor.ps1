<#
.SYNOPSIS
    We Enhanced Azure Service Health Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" All", " Service", " Planned", " Health", " Security")]
    [string]$WEEventType = " All",
    
    [Parameter(Mandatory=$false)]
    [int]$WEDaysBack = 7,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEActiveOnly
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName " Azure Service Health Monitor" -Version " 1.0" -Description " Monitor Azure service health and incidents"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.AlertsManagement'))) {
        throw " Azure connection validation failed"
    }

    if ($WESubscriptionId) { Set-AzContext -SubscriptionId $WESubscriptionId }

    $startTime = (Get-Date).AddDays(-$WEDaysBack)
    $serviceHealthEvents = Get-AzServiceHealth -StartTime $startTime

    if ($WEActiveOnly) {
        $serviceHealthEvents = $serviceHealthEvents | Where-Object { $_.Status -eq " Active" }
    }

    if ($WEEventType -ne " All") {
        $serviceHealthEvents = $serviceHealthEvents | Where-Object { $_.EventType -eq $WEEventType }
    }

    Write-WELog " Service Health Summary (Last $WEDaysBack days):" " INFO" -ForegroundColor Cyan
    Write-WELog " Total Events: $($serviceHealthEvents.Count)" " INFO" -ForegroundColor White
    
   ;  $eventSummary = $serviceHealthEvents | Group-Object EventType | ForEach-Object {
        [PSCustomObject]@{
            EventType = $_.Name
            Count = $_.Count
            ActiveEvents = ($_.Group | Where-Object { $_.Status -eq " Active" }).Count
        }
    }
    
    $eventSummary | Format-Table EventType, Count, ActiveEvents

    if ($serviceHealthEvents.Count -gt 0) {
        Write-WELog " Recent Events:" " INFO" -ForegroundColor Yellow
        $serviceHealthEvents | Sort-Object LastUpdateTime -Descending | Select-Object -First 10 | Format-Table Title, EventType, Status, LastUpdateTime
    }

} catch {
    Write-Log " ❌ Service health monitoring failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================