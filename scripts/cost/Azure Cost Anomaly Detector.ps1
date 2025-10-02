#Requires -Version 7.4
#Requires -Modules Az.Resources

<#.SYNOPSIS
    Azure Cost Anomaly Detector

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter()]
    [int]$DaysBack = 30,
    [Parameter()]
    [double]$AnomalyThreshold = 1.5,
    [Parameter()]
    [switch]$AlertOnAnomalies
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
    [string]$StartDate = (Get-Date).AddDays(-$DaysBack).ToString('yyyy-MM-dd')
    [string]$EndDate = (Get-Date).ToString('yyyy-MM-dd')
$UsageData = Get-AzConsumptionUsageDetail -StartDate $StartDate -EndDate $EndDate
    [string]$DailyCosts = $UsageData | Group-Object {($_.Date).ToString('yyyy-MM-dd')} | ForEach-Object {
        [PSCustomObject]@{
            Date = $_.Name
            TotalCost = ($_.Group | Measure-Object PretaxCost -Sum).Sum
        }
    } | Sort-Object Date
    [string]$AvgCost = ($DailyCosts | Measure-Object TotalCost -Average).Average
    [string]$anomalies = $DailyCosts | Where-Object { $_.TotalCost -gt ($AvgCost * $AnomalyThreshold) }
    Write-Host "Cost Anomaly Analysis:" -ForegroundColor Green
    Write-Host "Analysis Period: $StartDate to $EndDate" -ForegroundColor Green
    Write-Host "Average Daily Cost: $${avgCost:F2}" -ForegroundColor Green
    Write-Host "Anomaly Threshold: $${($AvgCost * $AnomalyThreshold):F2}" -ForegroundColor Green
    Write-Host "Anomalies Detected: $($anomalies.Count)" -ForegroundColor Green
    if ($anomalies.Count -gt 0) {
        Write-Host " `nAnomalous Days:" -ForegroundColor Green
    [string]$anomalies | Format-Table Date, @{Name="Cost" ;Expression={" $" + " {0:F2}" -f $_.TotalCost}}
    }
} catch { throw`n}
