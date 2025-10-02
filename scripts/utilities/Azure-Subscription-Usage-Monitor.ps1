#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Monitor subscription usage

.DESCRIPTION
    Monitor subscription usage
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter()]
    $SubscriptionId,
    [Parameter()]
    $Location = "East US",
    [Parameter()]
    [int]$WarningThreshold = 80,
    [Parameter()]
    [int]$CriticalThreshold = 95,
    [Parameter()]
    [switch]$ExportReport,
    [Parameter()]
    $OutputPath = ".\subscription-usage-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)
try {
        if (-not (Get-AzContext)) { Connect-AzAccount }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    $VmUsage = Get-AzVMUsage -Location $Location
    $NetworkUsage = Get-AzNetworkUsage -Location $Location
    $StorageUsage = Get-AzStorageUsage -Location $Location
        $UsageReport = @{
        SubscriptionId = (Get-AzContext).Subscription.Id
        SubscriptionName = (Get-AzContext).Subscription.Name
        Location = $Location
        ReportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputeUsage = $VmUsage | ForEach-Object {
            $UsagePercent = if ($_.Limit -gt 0) { [math]::Round(($_.CurrentValue / $_.Limit) * 100, 2) } else { 0 }
            @{
                Name = $_.Name.LocalizedValue
                Current = $_.CurrentValue
                Limit = $_.Limit
                UsagePercent = $UsagePercent
                Status = if ($UsagePercent -ge $CriticalThreshold) { "Critical" }
                        elseif ($UsagePercent -ge $WarningThreshold) { "Warning" }
                        else { "OK" }
            }
        }
        NetworkUsage = $NetworkUsage | ForEach-Object {
            $UsagePercent = if ($_.Limit -gt 0) { [math]::Round(($_.CurrentValue / $_.Limit) * 100, 2) } else { 0 }
            @{
                Name = $_.Name.LocalizedValue
                Current = $_.CurrentValue
                Limit = $_.Limit
                UsagePercent = $UsagePercent
                Status = if ($UsagePercent -ge $CriticalThreshold) { "Critical" }
                        elseif ($UsagePercent -ge $WarningThreshold) { "Warning" }
                        else { "OK" }
            }
        }
        StorageUsage = @{
            Name = $StorageUsage.Name.LocalizedValue
            Current = $StorageUsage.CurrentValue
            Limit = $StorageUsage.Limit
            UsagePercent = if ($StorageUsage.Limit -gt 0) { [math]::Round(($StorageUsage.CurrentValue / $StorageUsage.Limit) * 100, 2) } else { 0 }
        }
    }
        if ($ExportReport) {
        $UsageReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

    }
    $CriticalItems = @()
    $WarningItems = @()
    $UsageReport.ComputeUsage + $UsageReport.NetworkUsage | ForEach-Object {
        if ($_.Status -eq "Critical") { $CriticalItems += $_ }
        elseif ($_.Status -eq "Warning") { $WarningItems += $_ }
    }
    Write-Output ""
    Write-Output "                              SUBSCRIPTION USAGE REPORT"
    Write-Output ""
    Write-Output "Usage Summary for $($Location):"
    Write-Output "    Critical Items: $($CriticalItems.Count)"
    Write-Output "    Warning Items: $($WarningItems.Count)"
    Write-Output "    Total Quotas Monitored: $($UsageReport.ComputeUsage.Count + $UsageReport.NetworkUsage.Count + 1)"
    if ($CriticalItems.Count -gt 0) {
        Write-Output ""
        $CriticalItems | ForEach-Object {
            Write-Output "    $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)"
        }
    }
    if ($WarningItems.Count -gt 0) {
        Write-Output ""
        Write-Output "[WARN] Warning Usage (>$WarningThreshold%):"
        $WarningItems | ForEach-Object {
            Write-Output "    $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)"
        }
    }
    Write-Output ""

} catch { throw`n}
