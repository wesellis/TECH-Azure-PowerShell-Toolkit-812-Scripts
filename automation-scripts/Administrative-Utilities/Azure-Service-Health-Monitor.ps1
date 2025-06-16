# Azure Service Health Monitor
# Monitor Azure service health and incidents
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Service", "Planned", "Health", "Security")]
    [string]$EventType = "All",
    
    [Parameter(Mandatory=$false)]
    [int]$DaysBack = 7,
    
    [Parameter(Mandatory=$false)]
    [switch]$ActiveOnly
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Service Health Monitor" -Version "1.0" -Description "Monitor Azure service health and incidents"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.AlertsManagement'))) {
        throw "Azure connection validation failed"
    }

    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }

    $startTime = (Get-Date).AddDays(-$DaysBack)
    $serviceHealthEvents = Get-AzServiceHealth -StartTime $startTime

    if ($ActiveOnly) {
        $serviceHealthEvents = $serviceHealthEvents | Where-Object { $_.Status -eq "Active" }
    }

    if ($EventType -ne "All") {
        $serviceHealthEvents = $serviceHealthEvents | Where-Object { $_.EventType -eq $EventType }
    }

    Write-Host "Service Health Summary (Last $DaysBack days):" -ForegroundColor Cyan
    Write-Host "Total Events: $($serviceHealthEvents.Count)" -ForegroundColor White
    
    $eventSummary = $serviceHealthEvents | Group-Object EventType | ForEach-Object {
        [PSCustomObject]@{
            EventType = $_.Name
            Count = $_.Count
            ActiveEvents = ($_.Group | Where-Object { $_.Status -eq "Active" }).Count
        }
    }
    
    $eventSummary | Format-Table EventType, Count, ActiveEvents

    if ($serviceHealthEvents.Count -gt 0) {
        Write-Host "Recent Events:" -ForegroundColor Yellow
        $serviceHealthEvents | Sort-Object LastUpdateTime -Descending | Select-Object -First 10 | Format-Table Title, EventType, Status, LastUpdateTime
    }

} catch {
    Write-Log "❌ Service health monitoring failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
