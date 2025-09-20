#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Monitor subscription usage

.DESCRIPTION
    Monitor subscription usage
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Subscription Usage Monitor
#
[CmdletBinding()]

    [Parameter()]
    [string]$SubscriptionId,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter()]
    [int]$WarningThreshold = 80,
    [Parameter()]
    [int]$CriticalThreshold = 95,
    [Parameter()]
    [switch]$ExportReport,
    [Parameter()]
    [string]$OutputPath = ".\subscription-usage-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)
try {
        if (-not (Get-AzContext)) { Connect-AzAccount }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
        # Get compute usage
    $vmUsage = Get-AzVMUsage -Location $Location
    # Get network usage
    $networkUsage = Get-AzNetworkUsage -Location $Location
    # Get storage usage
    $storageUsage = Get-AzStorageUsage -Location $Location
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
        if ($ExportReport) {
        $usageReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        
    }
        # Display critical and warning items
    $criticalItems = @()
    $warningItems = @()
    $usageReport.ComputeUsage + $usageReport.NetworkUsage | ForEach-Object {
        if ($_.Status -eq "Critical") { $criticalItems += $_ }
        elseif ($_.Status -eq "Warning") { $warningItems += $_ }
    }
    Write-Host ""
    Write-Host "                              SUBSCRIPTION USAGE REPORT"
    Write-Host ""
    Write-Host "Usage Summary for $($Location):"
    Write-Host "    Critical Items: $($criticalItems.Count)"
    Write-Host "    Warning Items: $($warningItems.Count)"
    Write-Host "    Total Quotas Monitored: $($usageReport.ComputeUsage.Count + $usageReport.NetworkUsage.Count + 1)"
    if ($criticalItems.Count -gt 0) {
        Write-Host ""
        $criticalItems | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)"
        }
    }
    if ($warningItems.Count -gt 0) {
        Write-Host ""
        Write-Host "[WARN] Warning Usage (>$WarningThreshold%):"
        $warningItems | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)"
        }
    }
    Write-Host ""
    
} catch { throw }

