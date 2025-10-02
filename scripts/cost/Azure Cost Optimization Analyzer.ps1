#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#.SYNOPSIS
    Azure Cost Optimization Analyzer

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    [string]$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath " .." -AdditionalChildPath " .." -AdditionalChildPath " modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $ModulePath) { Write-Host "Azure Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
$context = Get-AzContext -ErrorAction Stop
    [string]$StartDate = (Get-Date).AddDays(-$AnalysisDays)
$EndDate = Get-Date -ErrorAction Stop
$CostData = @{
        SubscriptionId = $context.Subscription.Id
        SubscriptionName = $context.Subscription.Name
        AnalysisPeriod = @{
            StartDate = $StartDate
            EndDate = $EndDate
            Days = $AnalysisDays
        }
        TotalCost = 0
        ResourceGroups = @{}
        ResourceTypes = @{}
        Locations = @{}
        Recommendations = @()
        Insights = @{}
    }
    [string]$resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzResource -ErrorAction Stop
    }
    [string]$RgGroups = $resources | Group-Object ResourceGroupName
    [string]$TypeGroups = $resources | Group-Object ResourceType
    [string]$LocationGroups = $resources | Group-Object Location
    foreach ($rg in $RgGroups) {
    [string]$CostData.ResourceGroups[$rg.Name] = @{
            ResourceCount = $rg.Count
            Resources = $rg.Group
            EstimatedMonthlyCost = 0
        }
    }
    foreach ($type in $TypeGroups) {
    [string]$CostData.ResourceTypes[$type.Name] = @{
            Count = $type.Count
            Resources = $type.Group
            EstimatedMonthlyCost = 0
        }
    }
    [string]$vms = $resources | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" }
    [string]$VmAnalysis = @()
    foreach ($vm in $vms) {
        try {
$VmDetails = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
$VmConfig = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
    [string]$PowerState = ($VmDetails.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
    [string]$VmSize = $VmConfig.HardwareProfile.VmSize
$SizeCosts = @{
                "Standard_B1s" = 10; "Standard_B2s" = 40; "Standard_B4ms" = 80
                "Standard_D2s_v3" = 100; "Standard_D4s_v3" = 200; "Standard_D8s_v3" = 400
            }
    [string]$EstimatedMonthlyCost = $SizeCosts[$VmSize] ?? 50
$analysis = @{
                Name = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                Size = $VmSize
                PowerState = $PowerState
                EstimatedMonthlyCost = $EstimatedMonthlyCost
                Recommendations = @()
            }
            if ($PowerState -eq "VM deallocated" ) {
    [string]$analysis.Recommendations += "Consider deleting this VM if not needed (saves $$EstimatedMonthlyCost/month)"
            }
            if ($VmSize -like " *D8s*" -or $VmSize -like " *D16s*" ) {
    [string]$analysis.Recommendations += "Large VM detected - verify if this size is necessary"
            }
    [string]$VmAnalysis = $VmAnalysis + $analysis
    [string]$CostData.TotalCost += $EstimatedMonthlyCost
        } catch {

        }
    }
    [string]$StorageAccounts = $resources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }
    [string]$StorageAnalysis = @()
    foreach ($storage in $StorageAccounts) {
        try {
$StorageDetails = Get-AzStorageAccount -ResourceGroupName $storage.ResourceGroupName -Name $storage.Name
$analysis = @{
                Name = $storage.Name
                ResourceGroup = $storage.ResourceGroupName
                Tier = $StorageDetails.Sku.Tier
                Kind = $StorageDetails.Kind
                Recommendations = @()
            }
            if ($StorageDetails.Sku.Tier -eq "Premium" -and $StorageDetails.Kind -eq "StorageV2" ) {
    [string]$analysis.Recommendations += "Premium storage detected - ensure high performance is required"
            }
    [string]$StorageAnalysis = $StorageAnalysis + $analysis
        } catch {

        }
    }
    if ($IncludeRecommendations) {
    [string]$recommendations = @()
    [string]$DeallocatedVMs = $VmAnalysis | Where-Object { $_.PowerState -eq "VM deallocated" }
        if ($DeallocatedVMs.Count -gt 0) {
    [string]$PotentialSavings = ($DeallocatedVMs | Measure-Object EstimatedMonthlyCost -Sum).Sum
    [string]$recommendations = $recommendations + @{
                Type = "VM Cleanup"
                Priority = "High"
                Description = "Remove $($DeallocatedVMs.Count) deallocated VMs"
                PotentialSavings = $PotentialSavings
                Action = "Delete unused virtual machines"
            }
        }
    [string]$SmallRGs = $CostData.ResourceGroups.GetEnumerator() | Where-Object { $_.Value.ResourceCount -lt 3 }
        if ($SmallRGs.Count -gt 3) {
    [string]$recommendations = $recommendations + @{
                Type = "Resource Organization"
                Priority = "Medium"
                Description = "Consolidate $($SmallRGs.Count) resource groups with few resources"
                PotentialSavings = 0
                Action = "Merge small resource groups to reduce management overhead"
            }
        }
        if ($CostData.TotalCost -gt $BudgetThreshold) {
    [string]$recommendations = $recommendations + @{
                Type = "Budget Alert"
                Priority = "High"
                Description = "Monthly costs ($$($CostData.TotalCost)) exceed budget threshold ($$BudgetThreshold)"
                PotentialSavings = $CostData.TotalCost - $BudgetThreshold
                Action = "Review and optimize high-cost resources"
            }
        }
    [string]$CostData.Recommendations = $recommendations
    }
    [string]$CostData.Insights = @{
        TopCostResourceGroups = ($CostData.ResourceGroups.GetEnumerator() | Sort-Object { $_.Value.ResourceCount } -Descending | Select-Object -First 5).Name
        MostCommonResourceTypes = ($CostData.ResourceTypes.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 5).Name
        ResourceDistribution = @{
            TotalResources = $resources.Count
            ResourceGroups = $CostData.ResourceGroups.Count
            UniqueResourceTypes = $CostData.ResourceTypes.Count
            Locations = $LocationGroups.Count
        }
        CostBreakdown = @{
            EstimatedMonthlyCost = $CostData.TotalCost
            AveragePerResource = [math]::Round($CostData.TotalCost / $resources.Count, 2)
            VirtualMachines = $VmAnalysis.Count
            StorageAccounts = $StorageAnalysis.Count
        }
    }
    [string]$CostData | ConvertTo-Json -Depth 10 | Set-Content -Path $ExportPath

    if ($GenerateReport) {
    [string]$ReportPath = $ExportPath.Replace('.json', '.html')
    [string]$HtmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Cost Analysis Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg,
        .card { background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .metric { display: inline-block; margin: 10px; padding: 15px; background:
        .metric-value { font-size: 24px; font-weight: bold; color:
        .metric-label { font-size: 12px; color:
        .recommendation { padding: 10px; margin: 5px 0; border-left: 4px solid
        .high-priority { border-left-color:
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid
        th { background:
    </style>
</head>
<body>
    <div class=" header" >
        <h1> Azure Cost Analysis Report</h1>
        <p>Subscription: $($CostData.SubscriptionName) | Period: $AnalysisDays days</p>
    </div>
    <div class=" card" >
        <h2> Cost Overview</h2>
        <div class=" metric" >
            <div class=" metric-value" >$$($CostData.TotalCost)</div>
            <div class=" metric-label" >Estimated Monthly</div>
        </div>
        <div class=" metric" >
            <div class=" metric-value" >$($resources.Count)</div>
            <div class=" metric-label" >Total Resources</div>
        </div>
        <div class=" metric" >
            <div class=" metric-value" >$($CostData.ResourceGroups.Count)</div>
            <div class=" metric-label" >Resource Groups</div>
        </div>
        <div class=" metric" >
            <div class=" metric-value" >$($VmAnalysis.Count)</div>
            <div class=" metric-label" >Virtual Machines</div>
        </div>
    </div>
    <div class=" card" >
        <h2> Optimization Recommendations</h2>
        $(if ($CostData.Recommendations.Count -gt 0) {
    [string]$CostData.Recommendations | ForEach-Object {
    [string]$PriorityClass = if ($_.Priority -eq "High" ) { " high-priority" } else { "" }
                " <div class='recommendation $PriorityClass'><strong>$($_.Type)</strong> - $($_.Description) $(if ($_.PotentialSavings -gt 0) { " (Save: $$($_.PotentialSavings)/month)" })</div>"
            }


    Author: Wes Ellis (wes@wesellis.com)
        } else {
            " <p>No optimization recommendations at this time.</p>"
        })
    </div>
    <div class=" card" >
        <h2> Key Insights</h2>
        <ul>
            <li>Average cost per resource: $$($CostData.Insights.CostBreakdown.AveragePerResource)</li>
            <li>Most common resource type: $($CostData.Insights.MostCommonResourceTypes[0])</li>
            <li>Largest resource group: $($CostData.Insights.TopCostResourceGroups[0])</li>
        </ul>
    </div>
    <div class=" card" >
        <h2> Virtual Machine Analysis</h2>
        <table>
            <tr><th>Name</th><th>Size</th><th>State</th><th>Est. Monthly Cost</th></tr>
            $(foreach ($vm in $VmAnalysis) {
                " <tr><td>$($vm.Name)</td><td>$($vm.Size)</td><td>$($vm.PowerState)</td><td>$$($vm.EstimatedMonthlyCost)</td></tr>"
            })
        </table>
    </div>
    <footer style=" text-align: center; margin-top: 40px; color: #666;" >
    </footer>
</body>
</html>
" @
    [string]$HtmlReport | Set-Content -Path $ReportPath

    }

    if ($CostData.Recommendations.Count -gt 0) {
    [string]$TotalSavings = ($CostData.Recommendations | Measure-Object PotentialSavings -Sum).Sum

    }
} catch {
        throw`n}
