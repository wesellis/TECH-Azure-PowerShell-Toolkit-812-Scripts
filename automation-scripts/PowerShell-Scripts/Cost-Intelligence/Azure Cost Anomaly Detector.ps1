<#
.SYNOPSIS
    We Enhanced Azure Cost Anomaly Detector

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDaysBack = 30,
    
    [Parameter(Mandatory=$false)]
    [double]$WEAnomalyThreshold = 1.5,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEAlertOnAnomalies
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName " Azure Cost Anomaly Detector" -Version " 1.0" -Description " Detect unusual spending patterns"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.Billing', 'Az.CostManagement'))) {
        throw " Azure connection validation failed"
    }

    if ($WESubscriptionId) { Set-AzContext -SubscriptionId $WESubscriptionId }

    $startDate = (Get-Date).AddDays(-$WEDaysBack).ToString('yyyy-MM-dd')
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
   ;  $anomalies = $dailyCosts | Where-Object { $_.TotalCost -gt ($avgCost * $WEAnomalyThreshold) }

    Write-WELog " Cost Anomaly Analysis:" " INFO" -ForegroundColor Cyan
    Write-WELog " Analysis Period: $startDate to $endDate" " INFO" -ForegroundColor White
    Write-WELog " Average Daily Cost: $${avgCost:F2}" " INFO" -ForegroundColor Green
    Write-WELog " Anomaly Threshold: $${($avgCost * $WEAnomalyThreshold):F2}" " INFO" -ForegroundColor Yellow
    Write-WELog " Anomalies Detected: $($anomalies.Count)" " INFO" -ForegroundColor Red

    if ($anomalies.Count -gt 0) {
        Write-WELog " `nAnomalous Days:" " INFO" -ForegroundColor Red
        $anomalies | Format-Table Date, @{Name=" Cost";Expression={" $" + " {0:F2}" -f $_.TotalCost}}
    }

} catch {
    Write-Log " ❌ Cost anomaly detection failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================