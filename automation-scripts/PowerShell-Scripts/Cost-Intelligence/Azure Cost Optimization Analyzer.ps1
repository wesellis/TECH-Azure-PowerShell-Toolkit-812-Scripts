<#
.SYNOPSIS
    Azure Cost Optimization Analyzer

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter()][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()][int]$AnalysisDays = 30,
    [Parameter()][string]$ExportPath = " cost-analysis-$(Get-Date -Format 'yyyyMMdd').json" ,
    [Parameter()][decimal]$BudgetThreshold = 1000,
    [Parameter()][switch]$IncludeRecommendations,
    [Parameter()][switch]$GenerateReport
)
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath " .." -AdditionalChildPath " .." -AdditionalChildPath " modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
Write-Host "Azure Script Started" -ForegroundColor GreenName "Azure Cost Optimization Analyzer" -Description "AI-powered cost analysis with optimization recommendations"
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    # Progress stepNumber 1 -TotalSteps 7 -StepName "Data Collection" -Status "Gathering cost data..."
    # Set subscription context if specified
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
    $context = Get-AzContext -ErrorAction Stop

    # Get cost data
    $startDate = (Get-Date).AddDays(-$AnalysisDays)
    $endDate = Get-Date -ErrorAction Stop
    $costData = @{
        SubscriptionId = $context.Subscription.Id
        SubscriptionName = $context.Subscription.Name
        AnalysisPeriod = @{
            StartDate = $startDate
            EndDate = $endDate
            Days = $AnalysisDays
        }
        TotalCost = 0
        ResourceGroups = @{}
        ResourceTypes = @{}
        Locations = @{}
        Recommendations = @()
        Insights = @{}
    }
    # Progress stepNumber 2 -TotalSteps 7 -StepName "Resource Analysis" -Status "Analyzing resource utilization..."
    # Analyze resources
    $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzResource -ErrorAction Stop
    }

    # Group resources by various dimensions
    $rgGroups = $resources | Group-Object ResourceGroupName
    $typeGroups = $resources | Group-Object ResourceType
    $locationGroups = $resources | Group-Object Location
    foreach ($rg in $rgGroups) {
        $costData.ResourceGroups[$rg.Name] = @{
            ResourceCount = $rg.Count
            Resources = $rg.Group
            EstimatedMonthlyCost = 0
        }
    }
    foreach ($type in $typeGroups) {
        $costData.ResourceTypes[$type.Name] = @{
            Count = $type.Count
            Resources = $type.Group
            EstimatedMonthlyCost = 0
        }
    }
    # Progress stepNumber 3 -TotalSteps 7 -StepName "VM Analysis" -Status "Analyzing virtual machine efficiency..."
    #  VM analysis
    $vms = $resources | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" }
    $vmAnalysis = @()
    foreach ($vm in $vms) {
        try {
            $vmDetails = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            $vmConfig = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
            $powerState = ($vmDetails.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
$vmSize = $vmConfig.HardwareProfile.VmSize
            # Estimate monthly cost (simplified calculation)
$sizeCosts = @{
                "Standard_B1s" = 10; "Standard_B2s" = 40; "Standard_B4ms" = 80
                "Standard_D2s_v3" = 100; "Standard_D4s_v3" = 200; "Standard_D8s_v3" = 400
            }
            $estimatedMonthlyCost = $sizeCosts[$vmSize] ?? 50
            $analysis = @{
                Name = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                Size = $vmSize
                PowerState = $powerState
                EstimatedMonthlyCost = $estimatedMonthlyCost
                Recommendations = @()
            }
            # Generate recommendations
            if ($powerState -eq "VM deallocated" ) {
                $analysis.Recommendations += "Consider deleting this VM if not needed (saves $$estimatedMonthlyCost/month)"
            }
            if ($vmSize -like " *D8s*" -or $vmSize -like " *D16s*" ) {
                $analysis.Recommendations += "Large VM detected - verify if this size is necessary"
            }
            $vmAnalysis = $vmAnalysis + $analysis
            $costData.TotalCost += $estimatedMonthlyCost
        } catch {

        }
    }
    # Progress stepNumber 4 -TotalSteps 7 -StepName "Storage Analysis" -Status "Analyzing storage optimization..."
    # Storage account analysis
    $storageAccounts = $resources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }
    $storageAnalysis = @()
    foreach ($storage in $storageAccounts) {
        try {
            $storageDetails = Get-AzStorageAccount -ResourceGroupName $storage.ResourceGroupName -Name $storage.Name
            $analysis = @{
                Name = $storage.Name
                ResourceGroup = $storage.ResourceGroupName
                Tier = $storageDetails.Sku.Tier
                Kind = $storageDetails.Kind
                Recommendations = @()
            }
            if ($storageDetails.Sku.Tier -eq "Premium" -and $storageDetails.Kind -eq "StorageV2" ) {
                $analysis.Recommendations += "Premium storage detected - ensure high performance is required"
            }
            $storageAnalysis = $storageAnalysis + $analysis
        } catch {

        }
    }
    # Progress stepNumber 5 -TotalSteps 7 -StepName "AI Recommendations" -Status "Generating AI-powered recommendations..."
    if ($IncludeRecommendations) {
        # Generate  recommendations
        $recommendations = @()
        # VM Recommendations
        $deallocatedVMs = $vmAnalysis | Where-Object { $_.PowerState -eq "VM deallocated" }
        if ($deallocatedVMs.Count -gt 0) {
            $potentialSavings = ($deallocatedVMs | Measure-Object EstimatedMonthlyCost -Sum).Sum
            $recommendations = $recommendations + @{
                Type = "VM Cleanup"
                Priority = "High"
                Description = "Remove $($deallocatedVMs.Count) deallocated VMs"
                PotentialSavings = $potentialSavings
                Action = "Delete unused virtual machines"
            }
        }
        # Resource Group Consolidation
        $smallRGs = $costData.ResourceGroups.GetEnumerator() | Where-Object { $_.Value.ResourceCount -lt 3 }
        if ($smallRGs.Count -gt 3) {
            $recommendations = $recommendations + @{
                Type = "Resource Organization"
                Priority = "Medium"
                Description = "Consolidate $($smallRGs.Count) resource groups with few resources"
                PotentialSavings = 0
                Action = "Merge small resource groups to reduce management overhead"
            }
        }
        # Budget Alert
        if ($costData.TotalCost -gt $BudgetThreshold) {
            $recommendations = $recommendations + @{
                Type = "Budget Alert"
                Priority = "High"
                Description = "Monthly costs ($$($costData.TotalCost)) exceed budget threshold ($$BudgetThreshold)"
                PotentialSavings = $costData.TotalCost - $BudgetThreshold
                Action = "Review and optimize high-cost resources"
            }
        }
        $costData.Recommendations = $recommendations
    }
    # Progress stepNumber 6 -TotalSteps 7 -StepName "Insights" -Status "Generating cost insights..."
    # Generate insights
    $costData.Insights = @{
        TopCostResourceGroups = ($costData.ResourceGroups.GetEnumerator() | Sort-Object { $_.Value.ResourceCount } -Descending | Select-Object -First 5).Name
        MostCommonResourceTypes = ($costData.ResourceTypes.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 5).Name
        ResourceDistribution = @{
            TotalResources = $resources.Count
            ResourceGroups = $costData.ResourceGroups.Count
            UniqueResourceTypes = $costData.ResourceTypes.Count
            Locations = $locationGroups.Count
        }
        CostBreakdown = @{
            EstimatedMonthlyCost = $costData.TotalCost
            AveragePerResource = [math]::Round($costData.TotalCost / $resources.Count, 2)
            VirtualMachines = $vmAnalysis.Count
            StorageAccounts = $storageAnalysis.Count
        }
    }
    # Progress stepNumber 7 -TotalSteps 7 -StepName "Export" -Status "Exporting results..."
    # Export  analysis
    $costData | ConvertTo-Json -Depth 10 | Set-Content -Path $ExportPath

    if ($GenerateReport) {
        # Generate HTML report
$reportPath = $ExportPath.Replace('.json', '.html')
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Cost Analysis Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #1e3c72, #2a5298); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .card { background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #e3f2fd; border-radius: 8px; text-align: center; }
        .metric-value { font-size: 24px; font-weight: bold; color: #1976d2; }
        .metric-label { font-size: 12px; color: #666; }
        .recommendation { padding: 10px; margin: 5px 0; border-left: 4px solid #ff9800; background: #fff3e0; }
        .high-priority { border-left-color: #f44336; background: #ffebee; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f5f5f5; }
    </style>
</head>
<body>
    <div class=" header" >
        <h1> Azure Cost Analysis Report</h1>
        <p>Subscription: $($costData.SubscriptionName) | Period: $AnalysisDays days</p>
    </div>
    <div class=" card" >
        <h2> Cost Overview</h2>
        <div class=" metric" >
            <div class=" metric-value" >$$($costData.TotalCost)</div>
            <div class=" metric-label" >Estimated Monthly</div>
        </div>
        <div class=" metric" >
            <div class=" metric-value" >$($resources.Count)</div>
            <div class=" metric-label" >Total Resources</div>
        </div>
        <div class=" metric" >
            <div class=" metric-value" >$($costData.ResourceGroups.Count)</div>
            <div class=" metric-label" >Resource Groups</div>
        </div>
        <div class=" metric" >
            <div class=" metric-value" >$($vmAnalysis.Count)</div>
            <div class=" metric-label" >Virtual Machines</div>
        </div>
    </div>
    <div class=" card" >
        <h2> Optimization Recommendations</h2>
        $(if ($costData.Recommendations.Count -gt 0) {
            $costData.Recommendations | ForEach-Object {
                $priorityClass = if ($_.Priority -eq "High" ) { " high-priority" } else { "" }
                " <div class='recommendation $priorityClass'><strong>$($_.Type)</strong> - $($_.Description) $(if ($_.PotentialSavings -gt 0) { " (Save: $$($_.PotentialSavings)/month)" })</div>"
            }\n    Author: Wes Ellis (wes@wesellis.com)\n#>
        } else {
            " <p>No optimization recommendations at this time.</p>"
        })
    </div>
    <div class=" card" >
        <h2> Key Insights</h2>
        <ul>
            <li>Average cost per resource: $$($costData.Insights.CostBreakdown.AveragePerResource)</li>
            <li>Most common resource type: $($costData.Insights.MostCommonResourceTypes[0])</li>
            <li>Largest resource group: $($costData.Insights.TopCostResourceGroups[0])</li>
        </ul>
    </div>
    <div class=" card" >
        <h2> Virtual Machine Analysis</h2>
        <table>
            <tr><th>Name</th><th>Size</th><th>State</th><th>Est. Monthly Cost</th></tr>
            $(foreach ($vm in $vmAnalysis) {
                " <tr><td>$($vm.Name)</td><td>$($vm.Size)</td><td>$($vm.PowerState)</td><td>$$($vm.EstimatedMonthlyCost)</td></tr>"
            })
        </table>
    </div>
    <footer style=" text-align: center; margin-top: 40px; color: #666;" >
        <p>Generated by Azure Automation Scripts | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </footer>
</body>
</html>
" @
        $htmlReport | Set-Content -Path $reportPath

    }
        # Display summary

    if ($costData.Recommendations.Count -gt 0) {
        $totalSavings = ($costData.Recommendations | Measure-Object PotentialSavings -Sum).Sum

    }
} catch {
        throw
}\n