#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Detect cost anomalies

.DESCRIPTION
    Find unusual spending patterns in Azure costs
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter()]
    [string]$SubscriptionId,
    [Parameter()]
    [int]$DaysBack = 30,
    [Parameter()]
    [double]$AnomalyThreshold = 1.5,
    [Parameter()]
    [switch]$AlertOnAnomalies
)
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
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
    Write-Host "Cost Anomaly Analysis:"
    Write-Host "Analysis Period: $startDate to $endDate"
    Write-Host "Average Daily Cost: $${avgCost:F2}"
    Write-Host "Anomaly Threshold: $${($avgCost * $AnomalyThreshold):F2}"
    Write-Host "Anomalies Detected: $($anomalies.Count)"
    if ($anomalies.Count -gt 0) {
        Write-Host "`nAnomalous Days:"
        $anomalies | Format-Table Date, @{Name="Cost";Expression={"$" + "{0:F2}" -f $_.TotalCost}}
    }
} catch { throw }

