#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Subscription Usage Monitor
# Professional utility for tracking subscription limits and quotas
# Version: 1.0 | Resource usage and quota monitoring

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [int]$WarningThreshold = 80,
    
    [Parameter(Mandatory=$false)]
    [int]$CriticalThreshold = 95,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\subscription-usage-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

#region Functions

# Import common functions
# Module import removed - use #Requires instead

Show-Banner -ScriptName "Azure Subscription Usage Monitor" -Version "1.0" -Description "Monitor subscription limits, quotas, and resource usage"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 5 -StepName "Connection" -Status "Validating Azure connection"
    if (-not (Test-AzureConnection)) {
        throw "Azure connection validation failed"
    }

    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 5 -StepName "Usage Data" -Status "Gathering usage information"
    
    # Get compute usage
    $vmUsage = Get-AzVMUsage -Location $Location
    
    # Get network usage
    $networkUsage = Get-AzNetworkUsage -Location $Location
    
    # Get storage usage
    $storageUsage = Get-AzStorageUsage -Location $Location

    Write-ProgressStep -StepNumber 3 -TotalSteps 5 -StepName "Analysis" -Status "Analyzing usage patterns"
    
    $usageReport = @{
        SubscriptionId = (Get-AzContext).Subscription.Id
        SubscriptionName = (Get-AzContext).Subscription.Name
        Location = $Location
        ReportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputeUsage = $vmUsage | ForEach-Object {
            $usagePercent = if ($_.Limit -gt 0) { [math]::Round(($_.CurrentValue / $_.Limit) * 100, 2) } else { 0 }
            @{
                Name = $_.Name.LocalizedValue
                Current = $_.CurrentValue
                Limit = $_.Limit
                UsagePercent = $usagePercent
                Status = if ($usagePercent -ge $CriticalThreshold) { "Critical" } 
                        elseif ($usagePercent -ge $WarningThreshold) { "Warning" } 
                        else { "OK" }
            }
        }
        NetworkUsage = $networkUsage | ForEach-Object {
            $usagePercent = if ($_.Limit -gt 0) { [math]::Round(($_.CurrentValue / $_.Limit) * 100, 2) } else { 0 }
            @{
                Name = $_.Name.LocalizedValue
                Current = $_.CurrentValue
                Limit = $_.Limit
                UsagePercent = $usagePercent
                Status = if ($usagePercent -ge $CriticalThreshold) { "Critical" } 
                        elseif ($usagePercent -ge $WarningThreshold) { "Warning" } 
                        else { "OK" }
            }
        }
        StorageUsage = @{
            Name = $storageUsage.Name.LocalizedValue
            Current = $storageUsage.CurrentValue
            Limit = $storageUsage.Limit
            UsagePercent = if ($storageUsage.Limit -gt 0) { [math]::Round(($storageUsage.CurrentValue / $storageUsage.Limit) * 100, 2) } else { 0 }
        }
    }

    Write-ProgressStep -StepNumber 4 -TotalSteps 5 -StepName "Report Generation" -Status "Generating usage report"
    
    if ($ExportReport) {
        $usageReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "[OK] Usage report exported to: $OutputPath" -Level SUCCESS
    }

    Write-ProgressStep -StepNumber 5 -TotalSteps 5 -StepName "Summary" -Status "Displaying results"

    # Display critical and warning items
    $criticalItems = @()
    $warningItems = @()
    
    $usageReport.ComputeUsage + $usageReport.NetworkUsage | ForEach-Object {
        if ($_.Status -eq "Critical") { $criticalItems += $_ }
        elseif ($_.Status -eq "Warning") { $warningItems += $_ }
    }

    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                              SUBSCRIPTION USAGE REPORT"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    Write-Information " Usage Summary for $($Location):"
    Write-Information "   • Critical Items: $($criticalItems.Count)"
    Write-Information "   • Warning Items: $($warningItems.Count)"
    Write-Information "   • Total Quotas Monitored: $($usageReport.ComputeUsage.Count + $usageReport.NetworkUsage.Count + 1)"
    
    if ($criticalItems.Count -gt 0) {
        Write-Information ""
        Write-Information "� Critical Usage (>$CriticalThreshold%):"
        $criticalItems | ForEach-Object {
            Write-Information "   • $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)"
        }
    }
    
    if ($warningItems.Count -gt 0) {
        Write-Information ""
        Write-Information "[WARN] Warning Usage (>$WarningThreshold%):"
        $warningItems | ForEach-Object {
            Write-Information "   • $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)"
        }
    }
    
    Write-Information ""

    Write-Log " Subscription usage monitoring completed successfully!" -Level SUCCESS

} catch {
    Write-Log " Subscription usage monitoring failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity "Subscription Usage Monitoring" -Completed

#endregion
