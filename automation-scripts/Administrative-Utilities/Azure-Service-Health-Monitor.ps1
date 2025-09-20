<#
.SYNOPSIS
    Monitor service health

.DESCRIPTION
    Monitor service health
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Service Health Monitor
# Monitor Azure service health and incidents
param(
    [Parameter()]
    [string]$SubscriptionId,
    [Parameter()]
    [ValidateSet("All", "Service", "Planned", "Health", "Security")]
    [string]$EventType = "All",
    [Parameter()]
    [int]$DaysBack = 7,
    [Parameter()]
    [switch]$ActiveOnly
)
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }
    $startTime = (Get-Date).AddDays(-$DaysBack)
    $serviceHealthEvents = Get-AzServiceHealth -StartTime $startTime
    if ($ActiveOnly) {
        $serviceHealthEvents = $serviceHealthEvents | Where-Object { $_.Status -eq "Active" }
    }
    if ($EventType -ne "All") {
        $serviceHealthEvents = $serviceHealthEvents | Where-Object { $_.EventType -eq $EventType }
    }
    Write-Host "Service Health Summary (Last $DaysBack days):"
    Write-Host "Total Events: $($serviceHealthEvents.Count)"
    $eventSummary = $serviceHealthEvents | Group-Object EventType | ForEach-Object {
        [PSCustomObject]@{
            EventType = $_.Name
            Count = $_.Count
            ActiveEvents = ($_.Group | Where-Object { $_.Status -eq "Active" }).Count
        }
    }
    $eventSummary | Format-Table EventType, Count, ActiveEvents
    if ($serviceHealthEvents.Count -gt 0) {
        Write-Host "Recent Events:"
        $serviceHealthEvents | Sort-Object LastUpdateTime -Descending | Select-Object -First 10 | Format-Table Title, EventType, Status, LastUpdateTime
    }
} catch { throw }

