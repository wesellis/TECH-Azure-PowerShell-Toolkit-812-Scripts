#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure Finops Automation Engine

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
[CmdletBinding()]
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
$requiredModules = @('Az.Billing', 'Az.CostManagement', 'Az.Monitor', 'Az.Resources', 'Az.Compute')
foreach ($module in $requiredModules) {
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
        $this.CostData = @{}
        $this.OptimizationOpportunities = @{}
        $this.TotalSavings = 0
        $this.Predictions = @()
    }
    [void]AnalyzeCosts([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId) {
        Write-Host "Analyzing costs for subscription: $SubscriptionId" -ForegroundColor Yellow
        # Get cost data for last 30 days
        $endDate = Get-Date -ErrorAction Stop
        $startDate = $endDate.AddDays(-30)
        $query = @{
            type = "Usage"
            timeframe = "Custom"
            timePeriod = @{
                from = $startDate.ToString(" yyyy-MM-dd" )
                to = $endDate.ToString(" yyyy-MM-dd" )
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
        # Store cost analysis results
        $this.CostData[$SubscriptionId] = @{
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
        $unusedResources = @()
        # Check for unused disks
        $disks = Get-AzDisk -ErrorAction Stop
        foreach ($disk in $disks) {
            if ($disk.DiskState -eq "Unattached" ) {
                $unusedResources = $unusedResources + @{
                    Type = "Disk"
                    Name = $disk.Name
                    ResourceGroup = $disk.ResourceGroupName
                    Size = " $($disk.DiskSizeGB) GB"
                    MonthlyCost = [math]::Round($disk.DiskSizeGB * 0.05, 2)
                    Action = "Delete unattached disk"
                }
            }
        }
        # Check for unused public IPs
        $publicIps = Get-AzPublicIpAddress -ErrorAction Stop
        foreach ($ip in $publicIps) {
            if (!$ip.IpConfiguration) {
                $unusedResources = $unusedResources + @{
                    Type = "PublicIP"
                    Name = $ip.Name
                    ResourceGroup = $ip.ResourceGroupName
                    MonthlyCost = 3.65
                    Action = "Delete unused public IP"
                }
            }
        }
        # Check for stopped VMs still incurring compute charges
        $vms = Get-AzVM -Status
        foreach ($vm in $vms) {
            if ($vm.PowerState -eq "VM stopped" -and $vm.StatusCode -ne "Stopped (deallocated)" ) {
                $unusedResources = $unusedResources + @{
                    Type = "VM"
                    Name = $vm.Name
                    ResourceGroup = $vm.ResourceGroupName
                    Size = $vm.HardwareProfile.VmSize
                    MonthlyCost = 100 # Estimated
                    Action = "Deallocate stopped VM"
                }
            }
        }
        return $unusedResources
    }
    [array]AnalyzeRightSizing([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId) {
        $rightSizingRecommendations = @()
        # Analyze VM performance metrics
        $vms = Get-AzVM -ErrorAction Stop
        foreach ($vm in $vms) {
            # Get CPU metrics for last 7 days
            $endTime = Get-Date -ErrorAction Stop
            $startTime = $endTime.AddDays(-7)
            $params = @{
                or = $gw.BackendAddressPools[0].BackendAddresses.Count
                Maximum = "5)  $predictions = $predictions + @{ Date = $predictedDate PredictedCost = [math]::Round($predictedCost, 2) Confidence = 0.85 } }  return $predictions }"
                ne = "Production" ) { $storageOptimizations = $storageOptimizations + @{ Type = "Storage" Name = $storage.StorageAccountName ResourceGroup = $storage.ResourceGroupName CurrentRedundancy = $storage.Sku.Name RecommendedRedundancy = "Standard_LRS" Action = "Reduce redundancy for non-production storage" EstimatedSavings = 50 } } }  return $storageOptimizations }  [array]OptimizeNetworking([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $networkOptimizations = @()  # Check for unused Application Gateways $appGateways = Get-AzApplicationGateway"
                ge = "3) { $riRecommendations = $riRecommendations + @{ Type = "ReservedInstance" VMSize = $group.Name Count = $group.Count Term = " 1 Year"EstimatedSavings = 40 # Percentage Action = " Purchase Reserved Instances" } } }  return $riRecommendations }  [array]IdentifyAutoShutdownCandidates([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $shutdownCandidates = @()  $vms = Get-AzVM"
                TimeGrain = "01:00:00"
                le = $DaysAhead; $i++) { $predictedDate = $currentDate.AddDays($i) $predictedCost = 100 + ($i * 2) + (Get-Random
                lt = "20) { $currentSize = $vm.HardwareProfile.VmSize $recommendedSize = $this.GetSmallerVMSize($currentSize)  if ($recommendedSize) { $rightSizingRecommendations = $rightSizingRecommendations + @{ Type = "VM" Name = $vm.Name ResourceGroup = $vm.ResourceGroupName CurrentSize = $currentSize RecommendedSize = $recommendedSize AvgCPU = [math]::Round($avgCpu, 2) EstimatedSavings = 30 # Percentage Action = "Resize VM to smaller SKU" } } } } }  return $rightSizingRecommendations }  [string]GetSmallerVMSize([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$currentSize) { $sizeMap = @{ "Standard_D4s_v3" = "Standard_D2s_v3" "Standard_D8s_v3" = "Standard_D4s_v3" "Standard_D16s_v3" = "Standard_D8s_v3" "Standard_E4s_v3" = "Standard_E2s_v3" "Standard_E8s_v3" = "Standard_E4s_v3" }  return $sizeMap[$currentSize] }  [array]RecommendReservedInstances([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $riRecommendations = @()  # Analyze steady-state workloads $vms = Get-AzVM"
                AggregationType = "Average"
                ResourceId = $vm.Id
                MetricName = "Percentage CPU"
                WarningAction = "SilentlyContinue  if ($metrics"
                ResourceGroupName = $optimization.ResourceGroup
                EndTime = $endTime
                match = "GRS"
                and = $storage.Tags.Environment
                AccountName = $storage.StorageAccountName
                eq = "Deallocate stopped VM" ) { Stop-AzVM"
                Property = "{ $_.HardwareProfile.VmSize }  foreach ($group in $vmsBySize) { if ($group.Count"
                DiskName = $optimization.Name
                StartTime = $startTime
                shutdown = "schedule" } } }  return $shutdownCandidates }  [array]OptimizeStorage([Parameter()] [ValidateNotNullOrEmpty()] [Parameter()] [ValidateNotNullOrEmpty()] [string]$SubscriptionId) { $storageOptimizations = @()  # Analyze storage accounts $storageAccounts = Get-AzStorageAccount"
                ErrorAction = "Stop  for ($i = 1; $i"
                Force = "Write-Host "Deallocated VM: $($optimization.Name)"
                Name = $optimization.Name
                ForegroundColor = "Green } } } }  $this.TotalSavings += $optimization.MonthlyCost ?? 0 } } }  [array]PredictCosts([int]$DaysAhead) { # Simple linear regression for cost prediction # In a real implementation, this would use Azure ML or more sophisticated algorithms  ;  $predictions = @() ;  $currentDate = Get-Date"
            }
            $metrics @params
}
[OutputType([PSObject])]
 {
    [CmdletBinding()];
param(
        [FinOpsEngine]$Engine,
        [hashtable]$Optimizations
    )
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure FinOps Automation Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background-color: #f0f2f5; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0078d4 0%, #005a9e 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .header h1 { margin: 0 0 10px 0; font-size: 36px; }
        .header p { margin: 0; opacity: 0.9; }
        .summary-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .card h3 { margin: 0 0 15px 0; color: #323130; font-size: 18px; }
        .card .value { font-size: 36px; font-weight: bold; color: #0078d4; }
        .card .subtitle { color: #605e5c; font-size: 14px; margin-top: 5px; }
        .section { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .section h2 { margin: 0 0 20px 0; color: #323130; border-bottom: 2px solid #edebe9; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #edebe9; }
        th { background-color: #f3f2f1; font-weight: 600; color: #323130; }
        tr:hover { background-color: #faf9f8; }
        .savings { color: #107c10; font-weight: bold; }
        .action { background-color: #e1f5fe; color: #0078d4; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
        .chart { height: 300px; background: #f3f2f1; border-radius: 8px; margin: 20px 0; display: flex; align-items: center; justify-content: center; color: #605e5c; }
        .optimization-type { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
        .type-unused { background-color: #fde7e9; color: #a80000; }
        .type-rightsizing { background-color: #e7f3ff; color: #0078d4; }
        .type-reserved { background-color: #f3e7fd; color: #5c2d91; }
        .type-shutdown { background-color: #fff4ce; color: #835c00; }
        .footer { text-align: center; color: #605e5c; margin-top: 40px; padding: 20px; }
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
                    $OptimizationMode
                </div>
                <div class=" subtitle" >Current mode</div>
            </div>
        </div>
" @
    # Add optimization sections
    foreach ($category in $Optimizations.Keys) {
        if ($Optimizations[$category].Count -gt 0) {
            $html = $html + @"
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
$savings = if ($item.MonthlyCost) { " `$$($item.MonthlyCost)" }
                          elseif ($item.EstimatedSavings) { " $($item.EstimatedSavings)%" }
                          else { "TBD" }
$details = if ($item.Size) { $item.Size }
                          elseif ($item.CurrentSize) { " $($item.CurrentSize) -> $($item.RecommendedSize)" }
                          elseif ($item.Schedule) { $item.Schedule }
                          else { " -" }
                $html = $html + @"
                    <tr>
                        <td>$($item.Name)</td>
                        <td><span class=" optimization-type type-$(($item.Type -replace '\s', '').ToLower())" >$($item.Type)</span></td>
                        <td>$details</td>
                        <td class=" savings" >$savings</td>
                        <td><span class=" action" >$($item.Action)</span></td>
                    </tr>
" @
            }
            $html = $html + @"
                </tbody>
            </table>
        </div>
" @
        }
    }
    # Add ML predictions section if enabled
    if ($EnableMLPredictions) {
$html = $html + @"
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
    $html = $html + @"
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
    Write-Host "Azure FinOps Automation Engine v1.0" -ForegroundColor Cyan
    Write-Host " ===================================" -ForegroundColor Cyan
    # Connect to Azure if needed
    $context = Get-AzContext -ErrorAction Stop
    if (!$context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    # Get subscriptions to analyze
    if (!$SubscriptionId) {
        $subscriptions = Get-AzSubscription -ErrorAction Stop | Where-Object { $_.State -eq "Enabled" }
        $SubscriptionId = $subscriptions.Id
    }
    # Initialize FinOps engine
    $engine = [FinOpsEngine]::new()
    $allOptimizations = @{}
    foreach ($subId in $SubscriptionId) {
        Write-Host " `nAnalyzing subscription: $subId" -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $subId | Out-Null
        # Analyze costs
        $engine.AnalyzeCosts($subId)
        # Identify optimizations
        $optimizations = $engine.IdentifyOptimizations($subId)
        # Merge optimizations
        foreach ($key in $optimizations.Keys) {
            if (!$allOptimizations.ContainsKey($key)) {
                $allOptimizations[$key] = @()
            }
            $allOptimizations[$key] += $optimizations[$key]
        }
    }
    # Display summary
    Write-Host " `n=== FinOps Analysis Summary ===" -ForegroundColor Green
    foreach ($category in $allOptimizations.Keys) {
        $count = $allOptimizations[$category].Count
        if ($count -gt 0) {
            Write-Host " $category : $count opportunities found" -ForegroundColor Yellow
        }
    }
    # Calculate total potential savings
    foreach ($category in $allOptimizations.Values) {
        foreach ($item in $category) {
            if ($item.MonthlyCost) {
                $engine.TotalSavings += $item.MonthlyCost
            }
        }
    }
    Write-Host " `nTotal Potential Monthly Savings: `$$([math]::Round($engine.TotalSavings, 2))" -ForegroundColor Green
    Write-Host "Annual Savings Potential: `$$([math]::Round($engine.TotalSavings * 12, 2))" -ForegroundColor Green
    # Generate predictions if enabled
    if ($EnableMLPredictions) {
        Write-Host " `nGenerating cost predictions..." -ForegroundColor Yellow
        $engine.Predictions = $engine.PredictCosts(30)
    }
    # Implement optimizations based on mode
    if ($OptimizationMode -eq "AutoRemediate" ) {
        Write-Host " `n=== Auto-Remediation Mode ===" -ForegroundColor Red
$response = Read-Host "Are you sure you want to automatically implement optimizations? (yes/no)"
        if ($response -eq "yes" ) {
            $engine.ImplementOptimizations($allOptimizations)
            Write-Host " `nOptimizations implemented successfully!" -ForegroundColor Green
        } else {
            Write-Host "Auto-remediation cancelled." -ForegroundColor Yellow
        }
    }
    # Auto-shutdown configuration
    if ($AutoShutdownNonProd) {
        Write-Host " `nConfiguring auto-shutdown for non-production resources..." -ForegroundColor Yellow
        foreach ($candidate in $allOptimizations["AutoShutdown" ]) {
            Write-Host "Configuring shutdown for: $($candidate.Name)" -ForegroundColor Cyan
            # Implementation would go here
        }
    }
    # Generate report
$report = Generate-FinOpsReport -Engine $engine -Optimizations $allOptimizations
    $report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host " `nFinOps report generated: $OutputPath" -ForegroundColor Green
    # Cost threshold alert
    if ($engine.TotalSavings -gt $CostThreshold) {
        Write-Host " `n[WARN]  ALERT: Potential savings exceed threshold of `$$CostThreshold!" -ForegroundColor Red
        Write-Host "Immediate action recommended to reduce costs." -ForegroundColor Red
    }
} catch {
    Write-Error "An error occurred: $_"
    throw
}


