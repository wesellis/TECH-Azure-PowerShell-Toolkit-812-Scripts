#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]
param (
    [Parameter(HelpMessage="Target subscription ID (current if not specified)")]

    [ValidateNotNullOrEmpty()]

    [string] $SubscriptionId,
    [Parameter(HelpMessage="Specific resource group to analyze")]

    [ValidateNotNullOrEmpty()]

    [string] $ResourceGroupName,
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
    [string]$ErrorActionPreference = 'Stop'
    [string]$ToolName = "WE-Azure-ResourceOptimizer"
    [string]$Version = "4.0"
$StartTime = Get-Date -ErrorAction Stop
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "ANALYZE", "RECOMMEND")]
        [string]$Level = "INFO",
        [string]$Category = "GENERAL"
    )
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "White"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
        "ANALYZE" = "Cyan"
        "RECOMMEND" = "Magenta"
    }
    [string]$LogEntry = "$timestamp [$ToolName] [$Category] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
    [string]$LogPath = "$env:TEMP\WE-Azure-Optimization-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $LogPath -Value $LogEntry
}
function Get-WEResourceCostAnalysis -ErrorAction Stop {
    param(


        [ValidateNotNullOrEmpty()]

        [string] $SubscriptionId,


        [ValidateNotNullOrEmpty()]

        [string] $ResourceGroupName,
        [int]$DaysBack
    )
    Write-WEOptimizationLog "Performing  cost analysis" "ANALYZE" "COST"
    try {
$EndDate = Get-Date -ErrorAction Stop
    [string]$StartDate = $EndDate.AddDays(-$DaysBack)
$ConsumptionParams = @{
            StartDate = $StartDate.ToString("yyyy-MM-dd")
            EndDate = $EndDate.ToString("yyyy-MM-dd")
        }
        if ($ResourceGroupName) {
    [string]$ConsumptionParams.ResourceGroupName = $ResourceGroupName
        }
$CostData = Get-AzConsumptionUsageDetail -ErrorAction Stop @consumptionParams | Group-Object ResourceType
    [string]$CostAnalysis = @()
    [string]$TotalCost = 0
        foreach ($ResourceGroup in $CostData) {
    [string]$GroupCost = ($ResourceGroup.Group | Measure-Object -Property Cost -Sum).Sum
    [string]$TotalCost += $GroupCost
$analysis = @{
                ResourceType = $ResourceGroup.Name
                TotalCost = [math]::Round($GroupCost, 2)
                ResourceCount = $ResourceGroup.Count
                AverageCostPerResource = [math]::Round($GroupCost / $ResourceGroup.Count, 2)
                DailyAverageCost = [math]::Round($GroupCost / $DaysBack, 2)
                CostTrend = "Stable"  # Would need historical data for actual trend
                OptimizationPotential = "Medium"
            }
            if ($analysis.AverageCostPerResource -gt 100) {
    [string]$analysis.OptimizationPotential = "High"
            } elseif ($analysis.AverageCostPerResource -lt 10) {
    [string]$analysis.OptimizationPotential = "Low"
            }
    [string]$CostAnalysis += $analysis
        }
        Write-WEOptimizationLog "Cost analysis complete - Total: $([math]::Round($TotalCost, 2))" "SUCCESS" "COST"
        return @{
            TotalCost = $TotalCost
            AnalysisPeriod = "$DaysBack days"
            ResourceTypeBreakdown = $CostAnalysis
            AnalysisDate = Get-Date -ErrorAction Stop
        }
    } catch {
        Write-WEOptimizationLog "Cost analysis failed: $($_.Exception.Message)" "ERROR" "COST"
        return $null
    }
}
function Get-WERightsizingRecommendations -ErrorAction Stop {
    param(
[ValidateNotNullOrEmpty()]
[string] $ResourceGroupName)
    Write-WEOptimizationLog "Analyzing resource rightsizing opportunities" "ANALYZE" "RIGHTSIZE"
    try {
    [string]$RightsizingRecommendations = @()
    [string]$vms = if ($ResourceGroupName) {
            Get-AzVM -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzVM -ErrorAction Stop
        }
        Write-WEOptimizationLog "Analyzing $($vms.Count) virtual machines" "INFO" "RIGHTSIZE"
        foreach ($vm in $vms) {
$VmRecommendation = @{
                ResourceName = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                CurrentSize = $vm.HardwareProfile.VmSize
                Location = $vm.Location
                PowerState = "Unknown"
                CpuUtilization = 0
                MemoryUtilization = 0
                DiskUtilization = 0
                RecommendedAction = "Monitor"
                PotentialSavings = 0
                Confidence = "Medium"
                Recommendations = @()
            }
            if ($vm.HardwareProfile.VmSize -like "*_D*_v2") {
    [string]$VmRecommendation.Recommendations += "Consider upgrading to v5 series for better price/performance"
    [string]$VmRecommendation.PotentialSavings = 15
            }
            if ($vm.HardwareProfile.VmSize -like "*_A*") {
    [string]$VmRecommendation.Recommendations += "Consider migrating from Basic tier to Standard tier"
    [string]$VmRecommendation.RecommendedAction = "Upgrade"
    [string]$VmRecommendation.PotentialSavings = 25
            }
    [string]$VmRecommendation.Recommendations += "Enable Azure Monitor for  utilization metrics"
    [string]$RightsizingRecommendations += $VmRecommendation
        }
    [string]$StorageAccounts = if ($ResourceGroupName) {
            Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzStorageAccount -ErrorAction Stop
        }
        foreach ($storage in $StorageAccounts) {
$StorageRecommendation = @{
                ResourceName = $storage.StorageAccountName
                ResourceGroup = $storage.ResourceGroupName
                ResourceType = "Storage Account"
                CurrentTier = $storage.Sku.Name
                AccessTier = $storage.AccessTier
                RecommendedAction = "Review"
                Recommendations = @()
                PotentialSavings = 0
            }
            if ($storage.Sku.Name -eq "Standard_LRS" -and $storage.AccessTier -eq "Hot") {
    [string]$StorageRecommendation.Recommendations += "Consider Cool tier for infrequently accessed data"
    [string]$StorageRecommendation.PotentialSavings = 30
            }
            if ($storage.Kind -eq "Storage") {
    [string]$StorageRecommendation.Recommendations += "Upgrade to StorageV2 for latest features and better pricing"
    [string]$StorageRecommendation.PotentialSavings = 10
            }
    [string]$RightsizingRecommendations += $StorageRecommendation
        }
        Write-WEOptimizationLog "Rightsizing analysis complete - $($RightsizingRecommendations.Count) resources analyzed" "SUCCESS" "RIGHTSIZE"
        return $RightsizingRecommendations
    } catch {
        Write-WEOptimizationLog "Rightsizing analysis failed: $($_.Exception.Message)" "ERROR" "RIGHTSIZE"
        return @()
    }
}
function Find-WEUnusedResources {
    param(
[ValidateNotNullOrEmpty()]
[string] $ResourceGroupName)
    Write-WEOptimizationLog "Scanning for unused and orphaned resources" "ANALYZE" "CLEANUP"
    try {
    [string]$UnusedResources = @()
    [string]$disks = if ($ResourceGroupName) {
            Get-AzDisk -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzDisk -ErrorAction Stop
        }
    [string]$UnattachedDisks = $disks | Where-Object { $_.ManagedBy -eq $null }
        foreach ($disk in $UnattachedDisks) {
    [string]$UnusedResources += @{
                ResourceName = $disk.Name
                ResourceType = "Managed Disk"
                ResourceGroup = $disk.ResourceGroupName
                Status = "Unattached"
                EstimatedMonthlyCost = [math]::Round($disk.DiskSizeGB * 0.05, 2)
                LastModified = $disk.TimeCreated
                RecommendedAction = "Review and delete if truly unused"
                Risk = "Low"
            }
        }
    [string]$nsgs = if ($ResourceGroupName) {
            Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzNetworkSecurityGroup -ErrorAction Stop
        }
    [string]$UnusedNSGs = $nsgs | Where-Object {
    [string]$_.NetworkInterfaces.Count -eq 0 -and $_.Subnets.Count -eq 0
        }
        foreach ($nsg in $UnusedNSGs) {
    [string]$UnusedResources += @{
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
    [string]$PublicIPs = if ($ResourceGroupName) {
            Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzPublicIpAddress -ErrorAction Stop
        }
    [string]$UnusedPublicIPs = $PublicIPs | Where-Object { $_.IpConfiguration -eq $null }
        foreach ($pip in $UnusedPublicIPs) {
    [string]$UnusedResources += @{
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
        Write-WEOptimizationLog "Found $($UnusedResources.Count) potentially unused resources" "SUCCESS" "CLEANUP"
        return $UnusedResources
    } catch {
        Write-WEOptimizationLog "Unused resource scan failed: $($_.Exception.Message)" "ERROR" "CLEANUP"
        return @()
    }
}
Write-WEOptimizationLog "Wesley Ellis Azure Resource Optimization Analyzer v$Version Starting" "INFO"
Write-WEOptimizationLog "Author: Wesley Ellis | Contact: wesellis.com" "INFO"
Write-WEOptimizationLog "Analysis Type: $AnalysisType | Scope: $(if($ResourceGroupName){"Resource Group: $ResourceGroupName"}else{"Full Subscription"})" "INFO"
try {
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-WEOptimizationLog "Context set to subscription: $SubscriptionId" "INFO"
    }
$CurrentContext = Get-AzContext -ErrorAction Stop
    Write-WEOptimizationLog "Analyzing subscription: $($CurrentContext.Subscription.Name)" "INFO"
$OptimizationResults = @{
        SubscriptionInfo = @{
            Name = $CurrentContext.Subscription.Name
            Id = $CurrentContext.Subscription.Id
            TenantId = $CurrentContext.Tenant.Id
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
    switch ($AnalysisType) {
        "CostAnalysis" {
    [string]$OptimizationResults.Results.CostAnalysis = Get-WEResourceCostAnalysis -SubscriptionId $CurrentContext.Subscription.Id -ResourceGroupName $ResourceGroupName -DaysBack $CostAnalysisDays
        }
        "RightsizingRecommendations" {
    [string]$OptimizationResults.Results.RightsizingRecommendations = Get-WERightsizingRecommendations -ResourceGroupName $ResourceGroupName
        }
        "UnusedResources" {
    [string]$OptimizationResults.Results.UnusedResources = Find-WEUnusedResources -ResourceGroupName $ResourceGroupName
        }
        "FullOptimization" {
            Write-WEOptimizationLog "Performing  optimization analysis" "ANALYZE"
    [string]$OptimizationResults.Results.CostAnalysis = Get-WEResourceCostAnalysis -SubscriptionId $CurrentContext.Subscription.Id -ResourceGroupName $ResourceGroupName -DaysBack $CostAnalysisDays
    [string]$OptimizationResults.Results.RightsizingRecommendations = Get-WERightsizingRecommendations -ResourceGroupName $ResourceGroupName
    [string]$OptimizationResults.Results.UnusedResources = Find-WEUnusedResources -ResourceGroupName $ResourceGroupName
        }
    }
    [string]$TotalPotentialSavings = 0
    if ($OptimizationResults.Results.RightsizingRecommendations) {
    [string]$TotalPotentialSavings += ($OptimizationResults.Results.RightsizingRecommendations | Measure-Object -Property PotentialSavings -Sum).Sum
    }
    if ($OptimizationResults.Results.UnusedResources) {
    [string]$TotalPotentialSavings += ($OptimizationResults.Results.UnusedResources | Measure-Object -Property EstimatedMonthlyCost -Sum).Sum
    }
    [string]$ExecutionTime = (Get-Date) - $StartTime
    Write-WEOptimizationLog "Azure Resource Optimization Analysis Complete!" "SUCCESS"
    Write-WEOptimizationLog "   Analysis Type: $AnalysisType" "SUCCESS"
    Write-WEOptimizationLog "   Execution Time: $($ExecutionTime.TotalMinutes.ToString('F1')) minutes" "SUCCESS"
    Write-WEOptimizationLog "   Potential Monthly Savings: $([math]::Round($TotalPotentialSavings, 2))" "SUCCESS"
    Write-WEOptimizationLog "   Contact: wesellis.com for  optimization consulting" "SUCCESS"
    if ($ExportCSV -and $OptimizationResults.Results.RightsizingRecommendations) {
    [string]$CsvPath = "$env:TEMP\WE-Azure-Optimization-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    [string]$OptimizationResults.Results.RightsizingRecommendations | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-WEOptimizationLog "CSV report exported: $CsvPath" "SUCCESS"
    }
    if ($ExecutiveReport) {
    [string]$ReportPath = "$env:TEMP\WE-Azure-Executive-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    [string]$OptimizationResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-WEOptimizationLog "Executive report exported: $ReportPath" "SUCCESS"
    }
    return $OptimizationResults
} catch {
    Write-WEOptimizationLog "Optimization analysis failed: $($_.Exception.Message)" "ERROR"
    Write-WEOptimizationLog "Contact wesellis.com for enterprise support and consulting" "ERROR"
    throw`n}
