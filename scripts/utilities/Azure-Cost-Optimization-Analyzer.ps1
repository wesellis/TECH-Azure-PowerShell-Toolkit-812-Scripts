#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Compute, Az.Storage, Az.Billing

<#
.SYNOPSIS
    Analyze cost optimization opportunities in Azure

.DESCRIPTION
    Comprehensive Azure cost analysis and optimization tool that identifies
    underutilized resources, provides recommendations, and generates detailed reports

.PARAMETER SubscriptionId
    Azure subscription ID to analyze

.PARAMETER ResourceGroupName
    Specific resource group to analyze (optional)

.PARAMETER AnalysisDays
    Number of days to analyze (default 30)

.PARAMETER ExportPath
    Path to export the analysis results

.PARAMETER BudgetThreshold
    Budget threshold for recommendations

.PARAMETER IncludeRecommendations
    Include detailed recommendations in the analysis

.PARAMETER GenerateReport
    Generate HTML report

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateRange(1, 365)]
    [int]$AnalysisDays = 30,

    [Parameter()]
    [string]$ExportPath = "cost-analysis-$(Get-Date -Format 'yyyyMMdd').json",

    [Parameter()]
    [ValidateRange(0, [decimal]::MaxValue)]
    [decimal]$BudgetThreshold = 1000,

    [Parameter()]
    [switch]$IncludeRecommendations,

    [Parameter()]
    [switch]$GenerateReport
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

try {
    Write-ColorOutput "Azure Cost Optimization Analyzer - Starting" -Level INFO
    Write-Host "============================================" -ForegroundColor DarkGray

    # Connect to Azure if needed
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-ColorOutput "Connecting to Azure..." -Level INFO
        Connect-AzAccount
        $context = Get-AzContext
    }

    if ($SubscriptionId) {
        Write-ColorOutput "Setting subscription: $SubscriptionId" -Level INFO
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        $context = Get-AzContext
    }

    Write-ColorOutput "Analyzing subscription: $($context.Subscription.Name)" -Level INFO

    # Initialize cost data structure
    $StartDate = (Get-Date).AddDays(-$AnalysisDays)
    $EndDate = Get-Date

    $CostData = @{
        SubscriptionId = $context.Subscription.Id
        SubscriptionName = $context.Subscription.Name
        AnalysisPeriod = @{
            StartDate = $StartDate.ToString("yyyy-MM-dd")
            EndDate = $EndDate.ToString("yyyy-MM-dd")
            Days = $AnalysisDays
        }
        TotalCost = 0
        ResourceGroups = @{}
        ResourceTypes = @{}
        Locations = @{}
        Recommendations = @()
        Insights = @{}
    }

    # Get resources
    Write-ColorOutput "Retrieving resources..." -Level INFO
    $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzResource
    }

    Write-ColorOutput "Found $($resources.Count) resources" -Level INFO

    # Group resources for analysis
    $RgGroups = $resources | Group-Object ResourceGroupName
    $TypeGroups = $resources | Group-Object ResourceType
    $LocationGroups = $resources | Group-Object Location

    # Analyze resource groups
    foreach ($rg in $RgGroups) {
        $CostData.ResourceGroups[$rg.Name] = @{
            ResourceCount = $rg.Count
            Resources = $rg.Group | Select-Object Name, ResourceType
            EstimatedMonthlyCost = 0
        }
    }

    # Analyze resource types
    foreach ($type in $TypeGroups) {
        $CostData.ResourceTypes[$type.Name] = @{
            Count = $type.Count
            Resources = $type.Group | Select-Object Name, ResourceGroupName
            EstimatedMonthlyCost = 0
        }
    }

    # Analyze VMs for optimization opportunities
    Write-ColorOutput "Analyzing virtual machines..." -Level INFO
    $vms = $resources | Where-Object { $_.ResourceType -eq "Microsoft.Compute/virtualMachines" }
    $VmAnalysis = @()

    foreach ($vm in $vms) {
        try {
            $VmDetails = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            $VmConfig = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name

            $PowerState = ($VmDetails.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
            $VmSize = $VmConfig.HardwareProfile.VmSize

            # Simple cost estimation (in real scenario, would use Pricing API)
            $SizeCosts = @{
                "Standard_B1s" = 10
                "Standard_B2s" = 40
                "Standard_B4ms" = 80
                "Standard_D2s_v3" = 100
                "Standard_D4s_v3" = 200
                "Standard_D8s_v3" = 400
                "Standard_D16s_v3" = 800
            }

            $EstimatedMonthlyCost = if ($SizeCosts.ContainsKey($VmSize)) {
                $SizeCosts[$VmSize]
            } else {
                50  # Default estimate
            }

            $analysis = @{
                Name = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                Size = $VmSize
                PowerState = $PowerState
                EstimatedMonthlyCost = $EstimatedMonthlyCost
                Recommendations = @()
            }

            # Generate recommendations
            if ($IncludeRecommendations) {
                if ($PowerState -eq "VM deallocated") {
                    $analysis.Recommendations += "Consider deleting this VM if not needed (saves `$$EstimatedMonthlyCost/month)"
                }

                if ($VmSize -like "*D8s*" -or $VmSize -like "*D16s*") {
                    $analysis.Recommendations += "Large VM detected - verify if this size is necessary"
                }

                if ($PowerState -eq "VM running" -and $VmSize -notlike "*_v3" -and $VmSize -notlike "*_v4" -and $VmSize -notlike "*_v5") {
                    $analysis.Recommendations += "Consider upgrading to newer VM generation for better price/performance"
                }
            }

            $VmAnalysis += $analysis
            $CostData.TotalCost += $EstimatedMonthlyCost
        }
        catch {
            Write-Verbose "Failed to analyze VM $($vm.Name): $_"
        }
    }

    $CostData.Insights["VirtualMachines"] = $VmAnalysis

    # Analyze storage accounts
    Write-ColorOutput "Analyzing storage accounts..." -Level INFO
    $storageAccounts = $resources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }
    $StorageAnalysis = @()

    foreach ($storage in $storageAccounts) {
        try {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $storage.ResourceGroupName -Name $storage.Name

            $analysis = @{
                Name = $storage.Name
                ResourceGroup = $storage.ResourceGroupName
                Sku = $storageAccount.Sku.Name
                Kind = $storageAccount.Kind
                AccessTier = $storageAccount.AccessTier
                Recommendations = @()
            }

            if ($IncludeRecommendations) {
                if ($storageAccount.Sku.Name -eq "Standard_GRS" -or $storageAccount.Sku.Name -eq "Standard_RAGRS") {
                    $analysis.Recommendations += "Consider using LRS if geo-redundancy is not required"
                }

                if ($storageAccount.AccessTier -eq "Hot" -and $storageAccount.Kind -eq "StorageV2") {
                    $analysis.Recommendations += "Review if Cool tier would be more cost-effective for infrequently accessed data"
                }
            }

            $StorageAnalysis += $analysis
        }
        catch {
            Write-Verbose "Failed to analyze storage account $($storage.Name): $_"
        }
    }

    $CostData.Insights["StorageAccounts"] = $StorageAnalysis

    # Generate recommendations summary
    if ($IncludeRecommendations) {
        Write-ColorOutput "Generating recommendations..." -Level INFO

        # VM recommendations
        $deallocatedVMs = $VmAnalysis | Where-Object { $_.PowerState -eq "VM deallocated" }
        if ($deallocatedVMs) {
            $potentialSavings = ($deallocatedVMs | Measure-Object -Property EstimatedMonthlyCost -Sum).Sum
            $CostData.Recommendations += "Delete $($deallocatedVMs.Count) deallocated VMs to save `$$potentialSavings/month"
        }

        # Oversized VMs
        $largeVMs = $VmAnalysis | Where-Object { $_.Size -like "*D16s*" -or $_.Size -like "*D32s*" }
        if ($largeVMs) {
            $CostData.Recommendations += "Review $($largeVMs.Count) large VMs for right-sizing opportunities"
        }

        # Storage recommendations
        $grsStorage = $StorageAnalysis | Where-Object { $_.Sku -like "*GRS*" }
        if ($grsStorage) {
            $CostData.Recommendations += "Review $($grsStorage.Count) geo-redundant storage accounts"
        }
    }

    # Display results
    Write-Host "`nCost Analysis Summary:" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor DarkGray
    Write-Host "Subscription: $($CostData.SubscriptionName)"
    Write-Host "Analysis Period: $($CostData.AnalysisPeriod.Days) days"
    Write-Host "Total Resources: $($resources.Count)"
    Write-Host "Resource Groups: $($RgGroups.Count)"
    Write-Host "Estimated Monthly Cost: `$$($CostData.TotalCost)"

    if ($CostData.TotalCost -gt $BudgetThreshold) {
        Write-Warning "Monthly cost exceeds budget threshold of `$$BudgetThreshold"
    }

    # Display top resource types
    Write-Host "`nTop Resource Types:" -ForegroundColor Cyan
    $TypeGroups | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)"
    }

    # Display recommendations
    if ($CostData.Recommendations.Count -gt 0) {
        Write-Host "`nRecommendations:" -ForegroundColor Yellow
        foreach ($recommendation in $CostData.Recommendations) {
            Write-Host "  • $recommendation"
        }
    }

    # Export results
    $CostData | ConvertTo-Json -Depth 10 | Out-File -FilePath $ExportPath -Encoding UTF8
    Write-ColorOutput "Results exported to: $ExportPath" -Level SUCCESS

    # Generate HTML report if requested
    if ($GenerateReport) {
        $reportPath = $ExportPath -replace '\.json$', '.html'
        $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Cost Optimization Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078d4; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #0078d4; color: white; }
        .recommendation { background-color: #fff4ce; padding: 10px; margin: 10px 0; border-left: 4px solid #ffb900; }
    </style>
</head>
<body>
    <h1>Azure Cost Optimization Report</h1>
    <p>Generated: $(Get-Date)</p>
    <p>Subscription: $($CostData.SubscriptionName)</p>
    <p>Analysis Period: $($CostData.AnalysisPeriod.Days) days</p>
    <p>Total Resources: $($resources.Count)</p>
    <p>Estimated Monthly Cost: `$$($CostData.TotalCost)</p>
</body>
</html>
"@
        $htmlReport | Out-File -FilePath $reportPath -Encoding UTF8
        Write-ColorOutput "HTML report generated: $reportPath" -Level SUCCESS
    }

    Write-ColorOutput "`nCost analysis completed successfully!" -Level SUCCESS
}
catch {
    Write-ColorOutput "Cost analysis failed: $($_.Exception.Message)" -Level ERROR
    throw
}