<#
.SYNOPSIS
    We Enhanced Azure Subscription Usage Monitor

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
    [string]$WELocation = " East US",
    
    [Parameter(Mandatory=$false)]
    [int]$WEWarningThreshold = 80,
    
    [Parameter(Mandatory=$false)]
    [int]$WECriticalThreshold = 95,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\subscription-usage-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

Show-Banner -ScriptName " Azure Subscription Usage Monitor" -Version " 1.0" -Description " Monitor subscription limits, quotas, and resource usage"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 5 -StepName " Connection" -Status " Validating Azure connection"
    if (-not (Test-AzureConnection)) {
        throw " Azure connection validation failed"
    }

    if ($WESubscriptionId) {
        Set-AzContext -SubscriptionId $WESubscriptionId
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 5 -StepName " Usage Data" -Status " Gathering usage information"
    
    # Get compute usage
    $vmUsage = Get-AzVMUsage -Location $WELocation
    
    # Get network usage
    $networkUsage = Get-AzNetworkUsage -Location $WELocation
    
    # Get storage usage
    $storageUsage = Get-AzStorageUsage -Location $WELocation

    Write-ProgressStep -StepNumber 3 -TotalSteps 5 -StepName " Analysis" -Status " Analyzing usage patterns"
    
    $usageReport = @{
        SubscriptionId = (Get-AzContext).Subscription.Id
        SubscriptionName = (Get-AzContext).Subscription.Name
        Location = $WELocation
        ReportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputeUsage = $vmUsage | ForEach-Object {
            $usagePercent = if ($_.Limit -gt 0) { [math]::Round(($_.CurrentValue / $_.Limit) * 100, 2) } else { 0 }
            @{
                Name = $_.Name.LocalizedValue
                Current = $_.CurrentValue
                Limit = $_.Limit
                UsagePercent = $usagePercent
                Status = if ($usagePercent -ge $WECriticalThreshold) { " Critical" } 
                        elseif ($usagePercent -ge $WEWarningThreshold) { " Warning" } 
                        else { " OK" }
            }
        }
        NetworkUsage = $networkUsage | ForEach-Object {
            $usagePercent = if ($_.Limit -gt 0) { [math]::Round(($_.CurrentValue / $_.Limit) * 100, 2) } else { 0 }
            @{
                Name = $_.Name.LocalizedValue
                Current = $_.CurrentValue
                Limit = $_.Limit
                UsagePercent = $usagePercent
                Status = if ($usagePercent -ge $WECriticalThreshold) { " Critical" } 
                        elseif ($usagePercent -ge $WEWarningThreshold) { " Warning" } 
                        else { " OK" }
            }
        }
        StorageUsage = @{
            Name = $storageUsage.Name.LocalizedValue
            Current = $storageUsage.CurrentValue
            Limit = $storageUsage.Limit
            UsagePercent = if ($storageUsage.Limit -gt 0) { [math]::Round(($storageUsage.CurrentValue / $storageUsage.Limit) * 100, 2) } else { 0 }
        }
    }

    Write-ProgressStep -StepNumber 4 -TotalSteps 5 -StepName " Report Generation" -Status " Generating usage report"
    
    if ($WEExportReport) {
        $usageReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $WEOutputPath -Encoding UTF8
        Write-Log " ✓ Usage report exported to: $WEOutputPath" -Level SUCCESS
    }

    Write-ProgressStep -StepNumber 5 -TotalSteps 5 -StepName " Summary" -Status " Displaying results"

    # Display critical and warning items
    $criticalItems = @()
   ;  $warningItems = @()
    
    $usageReport.ComputeUsage + $usageReport.NetworkUsage | ForEach-Object {
        if ($_.Status -eq " Critical") { $criticalItems = $criticalItems + $_ }
        elseif ($_.Status -eq " Warning") { $warningItems = $warningItems + $_ }
    }

    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                              SUBSCRIPTION USAGE REPORT" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    Write-WELog " 📊 Usage Summary for $($WELocation):" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Critical Items: $($criticalItems.Count)" " INFO" -ForegroundColor Red
    Write-WELog "   • Warning Items: $($warningItems.Count)" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Total Quotas Monitored: $($usageReport.ComputeUsage.Count + $usageReport.NetworkUsage.Count + 1)" " INFO" -ForegroundColor White
    
    if ($criticalItems.Count -gt 0) {
        Write-WELog "" " INFO"
        Write-WELog " 🚨 Critical Usage (>$WECriticalThreshold%):" " INFO" -ForegroundColor Red
        $criticalItems | ForEach-Object {
            Write-WELog "   • $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)" " INFO" -ForegroundColor White
        }
    }
    
    if ($warningItems.Count -gt 0) {
        Write-WELog "" " INFO"
        Write-WELog " ⚠️ Warning Usage (>$WEWarningThreshold%):" " INFO" -ForegroundColor Yellow
        $warningItems | ForEach-Object {
            Write-WELog "   • $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)" " INFO" -ForegroundColor White
        }
    }
    
    Write-WELog "" " INFO"

    Write-Log " ✅ Subscription usage monitoring completed successfully!" -Level SUCCESS

} catch {
    Write-Log " ❌ Subscription usage monitoring failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity " Subscription Usage Monitoring" -Completed


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================