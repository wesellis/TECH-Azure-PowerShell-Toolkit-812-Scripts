# Azure Cost Anomaly Detector
# Detect unusual spending patterns and cost anomalies
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysBack = 30,
    
    [Parameter(Mandatory=$false)]
    [double]$AnomalyThreshold = 1.5,
    
    [Parameter(Mandatory=$false)]
    [switch]$AlertOnAnomalies
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Cost Anomaly Detector" -Version "1.0" -Description "Detect unusual spending patterns"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.Billing', 'Az.CostManagement'))) {
        throw "Azure connection validation failed"
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

    Write-Information "Cost Anomaly Analysis:"
    Write-Information "Analysis Period: $startDate to $endDate"
    Write-Information "Average Daily Cost: $${avgCost:F2}"
    Write-Information "Anomaly Threshold: $${($avgCost * $AnomalyThreshold):F2}"
    Write-Information "Anomalies Detected: $($anomalies.Count)"

    if ($anomalies.Count -gt 0) {
        Write-Information "`nAnomalous Days:"
        $anomalies | Format-Table Date, @{Name="Cost";Expression={"$" + "{0:F2}" -f $_.TotalCost}}
    }

} catch {
    Write-Log "❌ Cost anomaly detection failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
