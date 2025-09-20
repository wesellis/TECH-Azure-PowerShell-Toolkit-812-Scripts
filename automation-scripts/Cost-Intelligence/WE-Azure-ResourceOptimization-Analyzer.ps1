#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Wesley Ellis Azure Resource Optimization & Cost Intelligence Analyzer
# Contact: wesellis.com
# Version: 4.0 Enterprise Edition
#              rightsizing recommendations, and enterprise governance reporting
[CmdletBinding()]
param (
    [Parameter(HelpMessage="Target subscription ID (current if not specified)")]
    [string]$SubscriptionId,
    [Parameter(HelpMessage="Specific resource group to analyze")]
    [string]$ResourceGroupName,
    [Parameter(HelpMessage="Analysis scope")]
    [ValidateSet("CostAnalysis", "RightsizingRecommendations", "UnusedResources", "SecurityCompliance", "FullOptimization")]
    [string]$AnalysisType = "FullOptimization",
    [Parameter(HelpMessage="Cost analysis period in days")]
    [int]$CostAnalysisDays = 30,
    [Parameter(HelpMessage="Generate executive summary report")]
    [switch]$ExecutiveReport,
    [Parameter(HelpMessage="Export  CSV reports")]
    [switch]$ExportCSV,
    [Parameter(HelpMessage="Minimum cost threshold for recommendations")]
    [decimal]$MinCostThreshold = 50.00,
    [Parameter(HelpMessage="Include preview/beta resource types")]
    [switch]$IncludePreview
)
# Wesley Ellis Enterprise Framework
$ToolName = "WE-Azure-ResourceOptimizer"
$Version = "4.0"
$StartTime = Get-Date -ErrorAction Stop
# Enhanced enterprise logging
[OutputType([PSCustomObject])]
 {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "ANALYZE", "RECOMMEND")]
        [string]$Level = "INFO",
        [string]$Category = "GENERAL"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "White"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
        "ANALYZE" = "Cyan"
        "RECOMMEND" = "Magenta"
    }
    $logEntry = "$timestamp [$ToolName] [$Category] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
    # Enterprise audit logging
    $logPath = "$env:TEMP\WE-Azure-Optimization-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logPath -Value $logEntry
}
# Wesley Ellis Cost Analysis Engine
function Get-WEResourceCostAnalysis -ErrorAction Stop {
    param(
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [int]$DaysBack
    )
    Write-WEOptimizationLog "Performing  cost analysis" "ANALYZE" "COST"
    try {
        $endDate = Get-Date -ErrorAction Stop
        $startDate = $endDate.AddDays(-$DaysBack)
        # Get consumption data
        $consumptionParams = @{
            StartDate = $startDate.ToString("yyyy-MM-dd")
            EndDate = $endDate.ToString("yyyy-MM-dd")
        }
        if ($ResourceGroupName) {
            $consumptionParams.ResourceGroupName = $ResourceGroupName
        }
        #  cost breakdown
        $costData = Get-AzConsumptionUsageDetail -ErrorAction Stop @consumptionParams | Group-Object ResourceType
        $costAnalysis = @()
        $totalCost = 0
        foreach ($resourceGroup in $costData) {
            $groupCost = ($resourceGroup.Group | Measure-Object -Property Cost -Sum).Sum
            $totalCost += $groupCost
            $analysis = @{
                ResourceType = $resourceGroup.Name
                TotalCost = [math]::Round($groupCost, 2)
                ResourceCount = $resourceGroup.Count
                AverageCostPerResource = [math]::Round($groupCost / $resourceGroup.Count, 2)
                DailyAverageCost = [math]::Round($groupCost / $DaysBack, 2)
                CostTrend = "Stable"  # Would need historical data for actual trend
                OptimizationPotential = "Medium"
            }
            # Add optimization recommendations based on cost patterns
            if ($analysis.AverageCostPerResource -gt 100) {
                $analysis.OptimizationPotential = "High"
            } elseif ($analysis.AverageCostPerResource -lt 10) {
                $analysis.OptimizationPotential = "Low"
            }
            $costAnalysis += $analysis
        }
        Write-WEOptimizationLog "Cost analysis complete - Total: $([math]::Round($totalCost, 2))" "SUCCESS" "COST"
        return @{
            TotalCost = $totalCost
            AnalysisPeriod = "$DaysBack days"
            ResourceTypeBreakdown = $costAnalysis
            AnalysisDate = Get-Date -ErrorAction Stop
        }
    } catch {
        Write-WEOptimizationLog "Cost analysis failed: $($_.Exception.Message)" "ERROR" "COST"
        return $null
    }
}
# Enhanced Resource Rightsizing Analyzer
function Get-WERightsizingRecommendations -ErrorAction Stop {
    param([string]$ResourceGroupName)
    Write-WEOptimizationLog "Analyzing resource rightsizing opportunities" "ANALYZE" "RIGHTSIZE"
    try {
        $rightsizingRecommendations = @()
        # Get all VMs for analysis
        $vms = if ($ResourceGroupName) {
            Get-AzVM -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzVM -ErrorAction Stop
        }
        Write-WEOptimizationLog "Analyzing $($vms.Count) virtual machines" "INFO" "RIGHTSIZE"
        foreach ($vm in $vms) {
            # Get VM metrics (would need actual Azure Monitor queries in real implementation)
            $vmRecommendation = @{
                ResourceName = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                CurrentSize = $vm.HardwareProfile.VmSize
                Location = $vm.Location
                PowerState = "Unknown"
                CpuUtilization = 0  # Would get from Azure Monitor
                MemoryUtilization = 0  # Would get from Azure Monitor
                DiskUtilization = 0  # Would get from Azure Monitor
                RecommendedAction = "Monitor"
                PotentialSavings = 0
                Confidence = "Medium"
                Recommendations = @()
            }
            # Basic rightsizing logic (would be enhanced with actual metrics)
            if ($vm.HardwareProfile.VmSize -like "*_D*_v2") {
                $vmRecommendation.Recommendations += "Consider upgrading to v5 series for better price/performance"
                $vmRecommendation.PotentialSavings = 15
            }
            if ($vm.HardwareProfile.VmSize -like "*_A*") {
                $vmRecommendation.Recommendations += "Consider migrating from Basic tier to Standard tier"
                $vmRecommendation.RecommendedAction = "Upgrade"
                $vmRecommendation.PotentialSavings = 25
            }
            # Check for oversized instances (would use actual utilization metrics)
            $vmRecommendation.Recommendations += "Enable Azure Monitor for  utilization metrics"
            $rightsizingRecommendations += $vmRecommendation
        }
        # Analyze storage accounts
        $storageAccounts = if ($ResourceGroupName) {
            Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzStorageAccount -ErrorAction Stop
        }
        foreach ($storage in $storageAccounts) {
            $storageRecommendation = @{
                ResourceName = $storage.StorageAccountName
                ResourceGroup = $storage.ResourceGroupName
                ResourceType = "Storage Account"
                CurrentTier = $storage.Sku.Name
                AccessTier = $storage.AccessTier
                RecommendedAction = "Review"
                Recommendations = @()
                PotentialSavings = 0
            }
            # Storage optimization recommendations
            if ($storage.Sku.Name -eq "Standard_LRS" -and $storage.AccessTier -eq "Hot") {
                $storageRecommendation.Recommendations += "Consider Cool tier for infrequently accessed data"
                $storageRecommendation.PotentialSavings = 30
            }
            if ($storage.Kind -eq "Storage") {
                $storageRecommendation.Recommendations += "Upgrade to StorageV2 for latest features and better pricing"
                $storageRecommendation.PotentialSavings = 10
            }
            $rightsizingRecommendations += $storageRecommendation
        }
        Write-WEOptimizationLog "Rightsizing analysis complete - $($rightsizingRecommendations.Count) resources analyzed" "SUCCESS" "RIGHTSIZE"
        return $rightsizingRecommendations
    } catch {
        Write-WEOptimizationLog "Rightsizing analysis failed: $($_.Exception.Message)" "ERROR" "RIGHTSIZE"
        return @()
    }
}
# Unused Resource Detection Engine
function Find-WEUnusedResources {
    param([string]$ResourceGroupName)
    Write-WEOptimizationLog "Scanning for unused and orphaned resources" "ANALYZE" "CLEANUP"
    try {
        $unusedResources = @()
        # Find unattached disks
        $disks = if ($ResourceGroupName) {
            Get-AzDisk -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzDisk -ErrorAction Stop
        }
        $unattachedDisks = $disks | Where-Object { $_.ManagedBy -eq $null }
        foreach ($disk in $unattachedDisks) {
            $unusedResources += @{
                ResourceName = $disk.Name
                ResourceType = "Managed Disk"
                ResourceGroup = $disk.ResourceGroupName
                Status = "Unattached"
                EstimatedMonthlyCost = [math]::Round($disk.DiskSizeGB * 0.05, 2)  # Rough estimate
                LastModified = $disk.TimeCreated
                RecommendedAction = "Review and delete if truly unused"
                Risk = "Low"
            }
        }
        # Find unused network security groups
        $nsgs = if ($ResourceGroupName) {
            Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzNetworkSecurityGroup -ErrorAction Stop
        }
        $unusedNSGs = $nsgs | Where-Object {
            $_.NetworkInterfaces.Count -eq 0 -and $_.Subnets.Count -eq 0
        }
        foreach ($nsg in $unusedNSGs) {
            $unusedResources += @{
                ResourceName = $nsg.Name
                ResourceType = "Network Security Group"
                ResourceGroup = $nsg.ResourceGroupName
                Status = "Not Associated"
                EstimatedMonthlyCost = 0
                LastModified = "Unknown"
                RecommendedAction = "Delete if no longer needed"
                Risk = "Low"
            }
        }
        # Find unused public IPs
        $publicIPs = if ($ResourceGroupName) {
            Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzPublicIpAddress -ErrorAction Stop
        }
        $unusedPublicIPs = $publicIPs | Where-Object { $_.IpConfiguration -eq $null }
        foreach ($pip in $unusedPublicIPs) {
            $unusedResources += @{
                ResourceName = $pip.Name
                ResourceType = "Public IP Address"
                ResourceGroup = $pip.ResourceGroupName
                Status = "Unassigned"
                EstimatedMonthlyCost = if ($pip.Sku.Name -eq "Standard") { 3.65 } else { 2.92 }
                LastModified = "Unknown"
                RecommendedAction = "Delete if no longer needed"
                Risk = "Low"
            }
        }
        Write-WEOptimizationLog "Found $($unusedResources.Count) potentially unused resources" "SUCCESS" "CLEANUP"
        return $unusedResources
    } catch {
        Write-WEOptimizationLog "Unused resource scan failed: $($_.Exception.Message)" "ERROR" "CLEANUP"
        return @()
    }
}
# Main Execution Block
Write-WEOptimizationLog "Wesley Ellis Azure Resource Optimization Analyzer v$Version Starting" "INFO"
Write-WEOptimizationLog "Author: Wesley Ellis | Contact: wesellis.com" "INFO"
Write-WEOptimizationLog "Analysis Type: $AnalysisType | Scope: $(if($ResourceGroupName){"Resource Group: $ResourceGroupName"}else{"Full Subscription"})" "INFO"
try {
    # Set subscription context if specified
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-WEOptimizationLog "Context set to subscription: $SubscriptionId" "INFO"
    }
    $currentContext = Get-AzContext -ErrorAction Stop
    Write-WEOptimizationLog "Analyzing subscription: $($currentContext.Subscription.Name)" "INFO"
    # Initialize results container
    $OptimizationResults = @{
        SubscriptionInfo = @{
            Name = $currentContext.Subscription.Name
            Id = $currentContext.Subscription.Id
            TenantId = $currentContext.Tenant.Id
        }
        AnalysisMetadata = @{
            AnalysisType = $AnalysisType
            ExecutionTime = $StartTime
            ToolVersion = $Version
            Author = "Wesley Ellis"
            Contact = "wesellis.com"
        }
        Results = @{}
    }
    # Execute analysis based on type
    switch ($AnalysisType) {
        "CostAnalysis" {
            $OptimizationResults.Results.CostAnalysis = Get-WEResourceCostAnalysis -SubscriptionId $currentContext.Subscription.Id -ResourceGroupName $ResourceGroupName -DaysBack $CostAnalysisDays
        }
        "RightsizingRecommendations" {
            $OptimizationResults.Results.RightsizingRecommendations = Get-WERightsizingRecommendations -ResourceGroupName $ResourceGroupName
        }
        "UnusedResources" {
            $OptimizationResults.Results.UnusedResources = Find-WEUnusedResources -ResourceGroupName $ResourceGroupName
        }
        "FullOptimization" {
            Write-WEOptimizationLog "Performing  optimization analysis" "ANALYZE"
            $OptimizationResults.Results.CostAnalysis = Get-WEResourceCostAnalysis -SubscriptionId $currentContext.Subscription.Id -ResourceGroupName $ResourceGroupName -DaysBack $CostAnalysisDays
            $OptimizationResults.Results.RightsizingRecommendations = Get-WERightsizingRecommendations -ResourceGroupName $ResourceGroupName
            $OptimizationResults.Results.UnusedResources = Find-WEUnusedResources -ResourceGroupName $ResourceGroupName
        }
    }
    # Calculate total optimization potential
    $totalPotentialSavings = 0
    if ($OptimizationResults.Results.RightsizingRecommendations) {
        $totalPotentialSavings += ($OptimizationResults.Results.RightsizingRecommendations | Measure-Object -Property PotentialSavings -Sum).Sum
    }
    if ($OptimizationResults.Results.UnusedResources) {
        $totalPotentialSavings += ($OptimizationResults.Results.UnusedResources | Measure-Object -Property EstimatedMonthlyCost -Sum).Sum
    }
    # Generate executive summary
    $executionTime = (Get-Date) - $StartTime
    Write-WEOptimizationLog "Azure Resource Optimization Analysis Complete!" "SUCCESS"
    Write-WEOptimizationLog "   Analysis Type: $AnalysisType" "SUCCESS"
    Write-WEOptimizationLog "   Execution Time: $($executionTime.TotalMinutes.ToString('F1')) minutes" "SUCCESS"
    Write-WEOptimizationLog "   Potential Monthly Savings: $([math]::Round($totalPotentialSavings, 2))" "SUCCESS"
    Write-WEOptimizationLog "   Contact: wesellis.com for  optimization consulting" "SUCCESS"
    # Export results if requested
    if ($ExportCSV -and $OptimizationResults.Results.RightsizingRecommendations) {
        $csvPath = "$env:TEMP\WE-Azure-Optimization-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $OptimizationResults.Results.RightsizingRecommendations | Export-Csv -Path $csvPath -NoTypeInformation
        Write-WEOptimizationLog "CSV report exported: $csvPath" "SUCCESS"
    }
    if ($ExecutiveReport) {
        $reportPath = "$env:TEMP\WE-Azure-Executive-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $OptimizationResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
        Write-WEOptimizationLog "Executive report exported: $reportPath" "SUCCESS"
    }
    return $OptimizationResults
} catch {
    Write-WEOptimizationLog "Optimization analysis failed: $($_.Exception.Message)" "ERROR"
    Write-WEOptimizationLog "Contact wesellis.com for enterprise support and consulting" "ERROR"
    throw
}
# Wesley Ellis Azure Enterprise Optimization Solutions
#  cost management and governance: wesellis.com

