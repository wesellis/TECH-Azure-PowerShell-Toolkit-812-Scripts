#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Service Health Monitor

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
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionId,
    [Parameter()]
    [ValidateSet("All" , "Service" , "Planned" , "Health" , "Security" )]
    $EventType = "All" ,
    [Parameter()]
    [int]$DaysBack = 7,
    [Parameter()]
    [switch]$ActiveOnly
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId }
    $StartTime = (Get-Date).AddDays(-$DaysBack)
    $ServiceHealthEvents = Get-AzServiceHealth -StartTime $StartTime
    if ($ActiveOnly) {
    $ServiceHealthEvents = $ServiceHealthEvents | Where-Object { $_.Status -eq "Active" }
    }
    if ($EventType -ne "All" ) {
    $ServiceHealthEvents = $ServiceHealthEvents | Where-Object { $_.EventType -eq $EventType }
    }
    Write-Output "Service Health Summary (Last $DaysBack days):" # Color: $2
    Write-Output "Total Events: $($ServiceHealthEvents.Count)" # Color: $2
    $EventSummary = $ServiceHealthEvents | Group-Object EventType | ForEach-Object {
        [PSCustomObject]@{
            EventType = $_.Name
            Count = $_.Count
            ActiveEvents = ($_.Group | Where-Object { $_.Status -eq "Active" }).Count
        }
    }
    $EventSummary | Format-Table EventType, Count, ActiveEvents
    if ($ServiceHealthEvents.Count -gt 0) {
        Write-Output "Recent Events:" # Color: $2
    $ServiceHealthEvents | Sort-Object LastUpdateTime -Descending | Select-Object -First 10 | Format-Table Title, EventType, Status, LastUpdateTime
    }
} catch { throw`n}
