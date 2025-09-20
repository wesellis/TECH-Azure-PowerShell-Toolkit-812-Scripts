<#
.SYNOPSIS
    Azure Subscription Usage Monitor

.DESCRIPTION
    Azure automation
#>
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
    [string]$Location = "East US" ,
    [Parameter()]
    [int]$WarningThreshold = 80,
    [Parameter()]
    [int]$CriticalThreshold = 95,
    [Parameter()]
    [switch]$ExportReport,
    [Parameter()]
    [string]$OutputPath = " .\subscription-usage-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    # Progress stepNumber 1 -TotalSteps 5 -StepName "Connection" -Status "Validating Azure connection"
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    # Progress stepNumber 2 -TotalSteps 5 -StepName "Usage Data" -Status "Gathering usage information"
    # Get compute usage
    $vmUsage = Get-AzVMUsage -Location $Location
    # Get network usage
    $networkUsage = Get-AzNetworkUsage -Location $Location
    # Get storage usage
    $storageUsage = Get-AzStorageUsage -Location $Location
    # Progress stepNumber 3 -TotalSteps 5 -StepName "Analysis" -Status "Analyzing usage patterns"
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
    # Progress stepNumber 4 -TotalSteps 5 -StepName "Report Generation" -Status "Generating usage report"
    if ($ExportReport) {
        $usageReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

    }
    # Progress stepNumber 5 -TotalSteps 5 -StepName "Summary" -Status "Displaying results"
    # Display critical and warning items
$criticalItems = @()
$warningItems = @()
    $usageReport.ComputeUsage + $usageReport.NetworkUsage | ForEach-Object {
        if ($_.Status -eq "Critical" ) { $criticalItems = $criticalItems + $_ }
        elseif ($_.Status -eq "Warning" ) {;  $warningItems = $warningItems + $_ }
    }
    Write-Host ""
    Write-Host "                              SUBSCRIPTION USAGE REPORT" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage Summary for $($Location):" -ForegroundColor Cyan
    Write-Host "    Critical Items: $($criticalItems.Count)" -ForegroundColor Red
    Write-Host "    Warning Items: $($warningItems.Count)" -ForegroundColor Yellow
    Write-Host "    Total Quotas Monitored: $($usageReport.ComputeUsage.Count + $usageReport.NetworkUsage.Count + 1)" -ForegroundColor White
    if ($criticalItems.Count -gt 0) {
        Write-Host ""
        Write-Host "Critical Usage (>$CriticalThreshold%):" -ForegroundColor Red
        $criticalItems | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)" -ForegroundColor White
        }
    }
    if ($warningItems.Count -gt 0) {
        Write-Host ""
        Write-Host "[WARN] Warning Usage (>$WarningThreshold%):" -ForegroundColor Yellow
        $warningItems | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Current)/$($_.Limit) ($($_.UsagePercent)%)" -ForegroundColor White
        }
    }
    Write-Host ""

} catch { throw }

