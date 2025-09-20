#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Cost Anomaly Detector

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
    $startDate = (Get-Date).AddDays(-$DaysBack).ToString('yyyy-MM-dd')
    $endDate = (Get-Date).ToString('yyyy-MM-dd')
    # Get usage data
    $usageData = Get-AzConsumptionUsageDetail -StartDate $startDate -EndDate $endDate
    # Group by day and calculate daily costs
    $dailyCosts = $usageData | Group-Object {($_.Date).ToString('yyyy-MM-dd')} | ForEach-Object {
        [PSCustomObject]@{
            Date = $_.Name
            TotalCost = ($_.Group | Measure-Object PretaxCost -Sum).Sum
        }
    } | Sort-Object Date
    # Calculate average and detect anomalies
$avgCost = ($dailyCosts | Measure-Object TotalCost -Average).Average
$anomalies = $dailyCosts | Where-Object { $_.TotalCost -gt ($avgCost * $AnomalyThreshold) }
    Write-Host "Cost Anomaly Analysis:" -ForegroundColor Cyan
    Write-Host "Analysis Period: $startDate to $endDate" -ForegroundColor White
    Write-Host "Average Daily Cost: $${avgCost:F2}" -ForegroundColor Green
    Write-Host "Anomaly Threshold: $${($avgCost * $AnomalyThreshold):F2}" -ForegroundColor Yellow
    Write-Host "Anomalies Detected: $($anomalies.Count)" -ForegroundColor Red
    if ($anomalies.Count -gt 0) {
        Write-Host " `nAnomalous Days:" -ForegroundColor Red
        $anomalies | Format-Table Date, @{Name="Cost" ;Expression={" $" + " {0:F2}" -f $_.TotalCost}}
    }
} catch { throw }\n

