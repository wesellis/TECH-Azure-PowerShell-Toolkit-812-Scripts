#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Monitor service health

.DESCRIPTION
    Monitor service health
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter()]
    $SubscriptionId,
    [Parameter()]
    [ValidateSet("All", "Service", "Planned", "Health", "Security")]
    $EventType = "All",
    [Parameter()]
    [int]$DaysBack = 7,
    [Parameter()]
    [switch]$ActiveOnly
)
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }
    $StartTime = (Get-Date).AddDays(-$DaysBack)
    $ServiceHealthEvents = Get-AzServiceHealth -StartTime $StartTime
    if ($ActiveOnly) {
        $ServiceHealthEvents = $ServiceHealthEvents | Where-Object { $_.Status -eq "Active" }
    }
    if ($EventType -ne "All") {
        $ServiceHealthEvents = $ServiceHealthEvents | Where-Object { $_.EventType -eq $EventType }
    }
    Write-Output "Service Health Summary (Last $DaysBack days):"
    Write-Output "Total Events: $($ServiceHealthEvents.Count)"
    $EventSummary = $ServiceHealthEvents | Group-Object EventType | ForEach-Object {
        [PSCustomObject]@{
            EventType = $_.Name
            Count = $_.Count
            ActiveEvents = ($_.Group | Where-Object { $_.Status -eq "Active" }).Count
        }
    }
    $EventSummary | Format-Table EventType, Count, ActiveEvents
    if ($ServiceHealthEvents.Count -gt 0) {
        Write-Output "Recent Events:"
        $ServiceHealthEvents | Sort-Object LastUpdateTime -Descending | Select-Object -First 10 | Format-Table Title, EventType, Status, LastUpdateTime
    }
} catch { throw`n}
