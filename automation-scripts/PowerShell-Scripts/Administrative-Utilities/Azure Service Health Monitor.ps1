<#
.SYNOPSIS
    Azure Service Health Monitor

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter()]
    [ValidateSet("All" , "Service" , "Planned" , "Health" , "Security" )]
    [string]$EventType = "All" ,
    [Parameter()]
    [int]$DaysBack = 7,
    [Parameter()]
    [switch]$ActiveOnly
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }
    $startTime = (Get-Date).AddDays(-$DaysBack)
    $serviceHealthEvents = Get-AzServiceHealth -StartTime $startTime
    if ($ActiveOnly) {
        $serviceHealthEvents = $serviceHealthEvents | Where-Object { $_.Status -eq "Active" }
    }
    if ($EventType -ne "All" ) {
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
} catch { throw }

