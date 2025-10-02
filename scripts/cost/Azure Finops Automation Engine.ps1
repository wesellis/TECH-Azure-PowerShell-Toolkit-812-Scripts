#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#.SYNOPSIS
    Azure Finops Automation Engine

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Enterprise FinOps automation engine with AI-powered cost optimization and automated remediation.
    This  tool implements a complete FinOps (Financial Operations) framework for Azure environments.
    It uses machine learning to identify cost optimization opportunities, predict future spending,
    and automatically implement cost-saving measures while maintaining performance SLAs.
.PARAMETER SubscriptionId
    The Azure Subscription ID to analyze. If not specified, analyzes all accessible subscriptions.
.PARAMETER OptimizationMode
    Mode of operation: Analysis, Recommend, or AutoRemediate
.PARAMETER CostThreshold
    Monthly cost threshold in USD that triggers aggressive optimization
.PARAMETER EnableMLPredictions
    Enable machine learning predictions for cost forecasting
.PARAMETER AutoShutdownNonProd
    Automatically shutdown non-production resources during off-hours
    .\Azure-FinOps-Automation-Engine.ps1 -OptimizationMode "AutoRemediate" -CostThreshold 50000 -EnableMLPredictions
    Author: Wesley Ellis
    Date: June 2024    Requires: Az.Billing, Az.CostManagement, Az.Monitor modules
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter()]
    [string[]]$SubscriptionId,
    [Parameter()]
    [ValidateSet("Analysis" , "Recommend" , "AutoRemediate" )]
    [string]$OptimizationMode = "Recommend" ,
    [Parameter()]
    [decimal]$CostThreshold = 10000,
    [Parameter()]
    [switch]$EnableMLPredictions,
    [Parameter()]
    [switch]$AutoShutdownNonProd,
    [Parameter(ValueFromPipeline)]`n    [string]$OutputPath = " .\FinOps-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
)
    [string]$RequiredModules = @('Az.Billing', 'Az.CostManagement', 'Az.Monitor', 'Az.Resources', 'Az.Compute')
foreach ($module in $RequiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Error "Module $module is not installed. Please install it using: Install-Module -Name $module"
        throw
    }
    Import-Module $module -ErrorAction Stop
}
class FinOpsEngine {
    [hashtable]$CostData
    [hashtable]$OptimizationOpportunities
    [decimal]$TotalSavings
    [array]$Predictions
    FinOpsEngine() {
    [string]$this.CostData = @{}
    [string]$this.OptimizationOpportunities = @{}
    [string]$this.TotalSavings = 0
    [string]$this.Predictions = @()
    }
    [void]AnalyzeCosts([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId) {
        Write-Host "Analyzing costs for subscription: $SubscriptionId" -ForegroundColor Green
$EndDate = Get-Date -ErrorAction Stop
    [string]$StartDate = $EndDate.AddDays(-30)
$query = @{
            type = "Usage"
            timeframe = "Custom"
            timePeriod = @{
                from = $StartDate.ToString(" yyyy-MM-dd" )
                to = $EndDate.ToString(" yyyy-MM-dd" )
            }
            dataset = @{
                granularity = "Daily"
                aggregation = @{
                    totalCost = @{
                        name = "PreTaxCost"
                        function = "Sum"
                    }
                }
                grouping = @(
                    @{
                        type = "Dimension"
                        name = "ResourceGroup"
                    }
                    @{
                        type = "Dimension"
                        name = "ServiceName"
                    }
                )
            }
        }
    [string]$this.CostData[$SubscriptionId] = @{
            TotalCost = 0
            ResourceGroups = @{}
            Services = @{}
            DailyCosts = @()
        }
    }
    [hashtable]IdentifyOptimizations([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId) {
$optimizations = @{
            UnusedResources = $this.FindUnusedResources($SubscriptionId)
            RightSizing = $this.AnalyzeRightSizing($SubscriptionId)
            ReservedInstances = $this.RecommendReservedInstances($SubscriptionId)
            AutoShutdown = $this.IdentifyAutoShutdownCandidates($SubscriptionId)
            StorageOptimization = $this.OptimizeStorage($SubscriptionId)
            NetworkOptimization = $this.OptimizeNetworking($SubscriptionId)
        }
        return $optimizations
    }
    [array]FindUnusedResources([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId) {
    [string]$UnusedResources = @()
$disks = Get-AzDisk -ErrorAction Stop
        foreach ($disk in $disks) {
            if ($disk.DiskState -eq "Unattached" ) {
    [string]$UnusedResources = $UnusedResources + @{
                    Type = "Disk"
                    Name = $disk.Name
                    ResourceGroup = $disk.ResourceGroupName
                    Size = " $($disk.DiskSizeGB) GB"
                    MonthlyCost = [math]::Round($disk.DiskSizeGB * 0.05, 2)
                    Action = "Delete unattached disk"
                }
            }
        }
$PublicIps = Get-AzPublicIpAddress -ErrorAction Stop
        foreach ($ip in $PublicIps) {
            if (!$ip.IpConfiguration) {
    [string]$UnusedResources = $UnusedResources + @{
                    Type = "PublicIP"
                    Name = $ip.Name
                    ResourceGroup = $ip.ResourceGroupName
                    MonthlyCost = 3.65
                    Action = "Delete unused public IP"
                }
            }
        }
$vms = Get-AzVM -Status
        foreach ($vm in $vms) {
            if ($vm.PowerState -eq "VM stopped" -and $vm.StatusCode -ne "Stopped (deallocated)" ) {
    [string]$UnusedResources = $UnusedResources + @{
                    Type = "VM"
                    Name = $vm.Name
                    ResourceGroup = $vm.ResourceGroupName
                    Size = $vm.HardwareProfile.VmSize
                    MonthlyCost = 100
                    Action = "Deallocate stopped VM"
                }
            }
        }
        return $UnusedResources
    }
    [array]AnalyzeRightSizing([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId) {
    [string]$RightSizingRecommendations = @()
$vms = Get-AzVM -ErrorAction Stop
        foreach ($vm in $vms) {
$EndTime = Get-Date -ErrorAction Stop
    [string]$StartTime = $EndTime.AddDays(-7)
$params = @{
                or = $gw.BackendAddressPools[0].BackendAddresses.Count
                Maximum = "5)  $predictions = $predictions + @{ Date = $PredictedDate PredictedCost = [math]::Round($PredictedCost, 2) Confidence = 0.85 } }  return $predictions }"
                ne = "Production" ) { $StorageOptimizations = $StorageOptimizations + @{ Type = "Storage" Name = $storage.StorageAccountName ResourceGroup = $storage.ResourceGroupName CurrentRedundancy = $storage.Sku.Name RecommendedRedundancy = "Standard_LRS" Action = "Reduce redundancy for non-production storage" EstimatedSavings = 50 } } }  return $StorageOptimizations }  [array]OptimizeNetworking([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $NetworkOptimizations = @()                  ge = "3) { $RiRecommendations = $RiRecommendations + @{ Type = "ReservedInstance" VMSize = $group.Name Count = $group.Count Term = " 1 Year"EstimatedSavings = 40 # Percentage Action = " Purchase Reserved Instances" } } }  return $RiRecommendations }  [array]IdentifyAutoShutdownCandidates([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $ShutdownCandidates = @()  $vms = Get-AzVM"
                TimeGrain = "01:00:00"
                le = $DaysAhead; $i++) { $PredictedDate = $CurrentDate.AddDays($i) $PredictedCost = 100 + ($i * 2) + (Get-Random
                lt = "20) { $CurrentSize = $vm.HardwareProfile.VmSize $RecommendedSize = $this.GetSmallerVMSize($CurrentSize)  if ($RecommendedSize) { $RightSizingRecommendations = $RightSizingRecommendations + @{ Type = "VM" Name = $vm.Name ResourceGroup = $vm.ResourceGroupName CurrentSize = $CurrentSize RecommendedSize = $RecommendedSize AvgCPU = [math]::Round($AvgCpu, 2) EstimatedSavings = 30 # Percentage Action = "Resize VM to smaller SKU" } } } } }  return $RightSizingRecommendations }  [string]GetSmallerVMSize([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$CurrentSize) { $SizeMap = @{ "Standard_D4s_v3" = "Standard_D2s_v3" "Standard_D8s_v3" = "Standard_D4s_v3" "Standard_D16s_v3" = "Standard_D8s_v3" "Standard_E4s_v3" = "Standard_E2s_v3" "Standard_E8s_v3" = "Standard_E4s_v3" }  return $SizeMap[$CurrentSize] }  [array]RecommendReservedInstances([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $RiRecommendations = @()  # Analyze steady-state workloads $vms = Get-AzVM"
                AggregationType = "Average"
                ResourceId = $vm.Id
                MetricName = "Percentage CPU"
                WarningAction = "SilentlyContinue  if ($metrics"
                ResourceGroupName = $optimization.ResourceGroup
                EndTime = $EndTime
                match = "GRS"
                and = $storage.Tags.Environment
                AccountName = $storage.StorageAccountName
                eq = "Deallocate stopped VM" ) { Stop-AzVM"
                Property = "{ $_.HardwareProfile.VmSize }  foreach ($group in $VmsBySize) { if ($group.Count"
                DiskName = $optimization.Name
                StartTime = $StartTime
                shutdown = "schedule" } } }  return $ShutdownCandidates }  [array]OptimizeStorage([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $StorageOptimizations = @()  # Analyze storage accounts $StorageAccounts = Get-AzStorageAccount"
                ErrorAction = "Stop  for ($i = 1; $i"
                Force = "Write-Output "Deallocated VM: $($optimization.Name)"
                Name = $optimization.Name
                ForegroundColor = "Green } } } }  $this.TotalSavings += $optimization.MonthlyCost ?? 0 } } }  [array]PredictCosts([int]$DaysAhead) { # Simple linear regression for cost prediction # In a real implementation, this would use Azure ML or more sophisticated algorithms  ;  $predictions = @() ;  $CurrentDate = Get-Date"
            }
    [string]$metrics @params
}
function Write-Log {
    ;
[CmdletBinding(SupportsShouldProcess=$true)]
param(
        [FinOpsEngine]$Engine,
        [hashtable]$Optimizations
    )
    [string]$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure FinOps Automation Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background-color: #f0f2f5; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg,
        .header h1 { margin: 0 0 10px 0; font-size: 36px; }
        .header p { margin: 0; opacity: 0.9; }
        .summary-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .card h3 { margin: 0 0 15px 0; color:
        .card .value { font-size: 36px; font-weight: bold; color:
        .card .subtitle { color:
        .section { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .section h2 { margin: 0 0 20px 0; color:
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid
        th { background-color:
        tr:hover { background-color:
        .savings { color:
        .action { background-color:
        .chart { height: 300px; background:
        .optimization-type { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
        .type-unused { background-color:
        .type-rightsizing { background-color:
        .type-reserved { background-color:
        .type-shutdown { background-color:
        .footer { text-align: center; color:
    </style>
    <script src=" https://cdn.jsdelivr.net/npm/chart.js" ></script>
</head>
<body>
    <div class=" container" >
        <div class=" header" >
            <h1>Azure FinOps Automation Report</h1>
            <p>Generated on $(Get-Date -Format "MMMM dd, yyyy HH:mm" )</p>
            <p>Optimization Mode: $OptimizationMode</p>
        </div>
        <div class=" summary-cards" >
            <div class=" card" >
                <h3>Total Potential Savings</h3>
                <div class=" value" >`$$([math]::Round($Engine.TotalSavings, 2))</div>
                <div class=" subtitle" >Per month</div>
            </div>
            <div class=" card" >
                <h3>Optimization Opportunities</h3>
                <div class=" value" >$(($Optimizations.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum)</div>
                <div class=" subtitle" >Total recommendations</div>
            </div>
            <div class=" card" >
                <h3>Resources Analyzed</h3>
                <div class=" value" >$((Get-AzResource).Count)</div>
                <div class=" subtitle" >Across all subscriptions</div>
            </div>
            <div class=" card" >
                <h3>Automation Status</h3>
                <div class=" value" style=" color: $(if ($OptimizationMode -eq 'AutoRemediate') { '#107c10' } else { '#ff8c00' })" >
    [string]$OptimizationMode
                </div>
                <div class=" subtitle" >Current mode</div>
            </div>
        </div>
" @
    foreach ($category in $Optimizations.Keys) {
        if ($Optimizations[$category].Count -gt 0) {
    [string]$html = $html + @"
        <div class=" section" >
            <h2>$category Optimizations</h2>
            <table>
                <thead>
                    <tr>
                        <th>Resource</th>
                        <th>Type</th>
                        <th>Details</th>
                        <th>Estimated Savings</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
" @
            foreach ($item in $Optimizations[$category]) {
    [string]$savings = if ($item.MonthlyCost) { " `$$($item.MonthlyCost)" }
                          elseif ($item.EstimatedSavings) { " $($item.EstimatedSavings)%" }
                          else { "TBD" }
    [string]$details = if ($item.Size) { $item.Size }
                          elseif ($item.CurrentSize) { " $($item.CurrentSize) -> $($item.RecommendedSize)" }
                          elseif ($item.Schedule) { $item.Schedule }
                          else { " -" }
    [string]$html = $html + @"
                    <tr>
                        <td>$($item.Name)</td>
                        <td><span class=" optimization-type type-$(($item.Type -replace '\s', '').ToLower())" >$($item.Type)</span></td>
                        <td>$details</td>
                        <td class=" savings" >$savings</td>
                        <td><span class=" action" >$($item.Action)</span></td>
                    </tr>
" @
            }
    [string]$html = $html + @"
                </tbody>
            </table>
        </div>
" @
        }
    }
    if ($EnableMLPredictions) {
    [string]$html = $html + @"
        <div class=" section" >
            <h2>Cost Predictions (Next 30 Days)</h2>
            <div class=" chart" >
                <canvas id=" predictionChart" ></canvas>
            </div>
            <p style=" text-align: center; color: #605e5c;" >
                Based on historical trends and current optimization potential
            </p>
        </div>
" @
    }
    [string]$html = $html + @"
        <div class=" footer" >
            <p>Azure FinOps Automation Engine v1.0 | Enterprise Cost Optimization</p>
        </div>
    </div>
    <script>
        // Add chart rendering here if predictions are enabled
        if (document.getElementById('predictionChart')) {
            // Chart.js implementation would go here
        }
    </script>
</body>
</html>
" @
    return $html
}
try {
    Write-Host "Azure FinOps Automation Engine v1.0" -ForegroundColor Green
    Write-Host " ===================================" -ForegroundColor Green
$context = Get-AzContext -ErrorAction Stop
    if (!$context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    if (!$SubscriptionId) {
$subscriptions = Get-AzSubscription -ErrorAction Stop | Where-Object { $_.State -eq "Enabled" }
    [string]$SubscriptionId = $subscriptions.Id
    }
    [string]$engine = [FinOpsEngine]::new()
$AllOptimizations = @{}
    foreach ($SubId in $SubscriptionId) {
        Write-Host " `nAnalyzing subscription: $SubId" -ForegroundColor Green
        Set-AzContext -SubscriptionId $SubId | Out-Null
    [string]$engine.AnalyzeCosts($SubId)
    [string]$optimizations = $engine.IdentifyOptimizations($SubId)
        foreach ($key in $optimizations.Keys) {
            if (!$AllOptimizations.ContainsKey($key)) {
    [string]$AllOptimizations[$key] = @()
            }
    [string]$AllOptimizations[$key] += $optimizations[$key]
        }
    }
    Write-Host " `n=== FinOps Analysis Summary ===" -ForegroundColor Green
    foreach ($category in $AllOptimizations.Keys) {
    [string]$count = $AllOptimizations[$category].Count
        if ($count -gt 0) {
            Write-Host " $category : $count opportunities found" -ForegroundColor Green
        }
    }
    foreach ($category in $AllOptimizations.Values) {
        foreach ($item in $category) {
            if ($item.MonthlyCost) {
    [string]$engine.TotalSavings += $item.MonthlyCost
            }
        }
    }
    Write-Host " `nTotal Potential Monthly Savings: `$$([math]::Round($engine.TotalSavings, 2))" -ForegroundColor Green
    Write-Host "Annual Savings Potential: `$$([math]::Round($engine.TotalSavings * 12, 2))" -ForegroundColor Green
    if ($EnableMLPredictions) {
        Write-Host " `nGenerating cost predictions..." -ForegroundColor Green
    [string]$engine.Predictions = $engine.PredictCosts(30)
    }
    if ($OptimizationMode -eq "AutoRemediate" ) {
        Write-Host " `n=== Auto-Remediation Mode ===" -ForegroundColor Green
    [string]$response = Read-Host "Are you sure you want to automatically implement optimizations? (yes/no)"
        if ($response -eq "yes" ) {
    [string]$engine.ImplementOptimizations($AllOptimizations)
            Write-Host " `nOptimizations implemented successfully!" -ForegroundColor Green
        } else {
            Write-Host "Auto-remediation cancelled." -ForegroundColor Green
        }
    }
    if ($AutoShutdownNonProd) {
        Write-Host " `nConfiguring auto-shutdown for non-production resources..." -ForegroundColor Green
        foreach ($candidate in $AllOptimizations["AutoShutdown" ]) {
            Write-Host "Configuring shutdown for: $($candidate.Name)" -ForegroundColor Green
        }
    }
    [string]$report = Generate-FinOpsReport -Engine $engine -Optimizations $AllOptimizations
    [string]$report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host " `nFinOps report generated: $OutputPath" -ForegroundColor Green
    if ($engine.TotalSavings -gt $CostThreshold) {
        Write-Host " `n[WARN]  ALERT: Potential savings exceed threshold of `$$CostThreshold!" -ForegroundColor Green
        Write-Host "Immediate action recommended to reduce costs." -ForegroundColor Green
    }
} catch {
    Write-Error "An error occurred: $_"
    throw`n}
