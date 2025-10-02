#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Detect cost anomalies

.DESCRIPTION
    Find unusual spending patterns in Azure costs
    Author: Wes Ellis (wes@wesellis.com)
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
    $StartDate = (Get-Date).AddDays(-$DaysBack).ToString('yyyy-MM-dd')
    $EndDate = (Get-Date).ToString('yyyy-MM-dd')
    $UsageData = Get-AzConsumptionUsageDetail -StartDate $StartDate -EndDate $EndDate
    $DailyCosts = $UsageData | Group-Object {($_.Date).ToString('yyyy-MM-dd')} | ForEach-Object {
        [PSCustomObject]@{
            Date = $_.Name
            TotalCost = ($_.Group | Measure-Object PretaxCost -Sum).Sum
        }
    } | Sort-Object Date
    $AvgCost = ($DailyCosts | Measure-Object TotalCost -Average).Average
    $anomalies = $DailyCosts | Where-Object { $_.TotalCost -gt ($AvgCost * $AnomalyThreshold) }
    Write-Output "Cost Anomaly Analysis:"
    Write-Output "Analysis Period: $StartDate to $EndDate"
    Write-Output "Average Daily Cost: $${avgCost:F2}"
    Write-Output "Anomaly Threshold: $${($AvgCost * $AnomalyThreshold):F2}"
    Write-Output "Anomalies Detected: $($anomalies.Count)"
    if ($anomalies.Count -gt 0) {
        Write-Output "`nAnomalous Days:"
        $anomalies | Format-Table Date, @{Name="Cost";Expression={"$" + "{0:F2}" -f $_.TotalCost}}
    }
} catch { throw`n}
