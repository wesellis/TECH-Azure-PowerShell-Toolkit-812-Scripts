# ============================================================================
# Script Name: Azure Resource Group Cost Calculator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Estimates costs for all resources in a Resource Group
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

Write-Host "Calculating estimated costs for Resource Group: $ResourceGroupName"

$Resources = Get-AzResource -ResourceGroupName $ResourceGroupName

$TotalEstimatedCost = 0
$CostBreakdown = @()

foreach ($Resource in $Resources) {
    $EstimatedMonthlyCost = 0
    
    switch ($Resource.ResourceType) {
        "Microsoft.Compute/virtualMachines" { $EstimatedMonthlyCost = 73.00 }
        "Microsoft.Storage/storageAccounts" { $EstimatedMonthlyCost = 25.00 }
        "Microsoft.Sql/servers/databases" { $EstimatedMonthlyCost = 200.00 }
        "Microsoft.Network/applicationGateways" { $EstimatedMonthlyCost = 125.00 }
        "Microsoft.ContainerInstance/containerGroups" { $EstimatedMonthlyCost = 50.00 }
        default { $EstimatedMonthlyCost = 10.00 }
    }
    
    $CostBreakdown += [PSCustomObject]@{
        ResourceName = $Resource.Name
        ResourceType = $Resource.ResourceType
        EstimatedMonthlyCost = $EstimatedMonthlyCost
    }
    
    $TotalEstimatedCost += $EstimatedMonthlyCost
}

Write-Host "`nCost Breakdown:"
foreach ($Item in $CostBreakdown) {
    Write-Host "  $($Item.ResourceName): $($Item.EstimatedMonthlyCost) USD/month"
}

Write-Host "`nTotal Estimated Monthly Cost: $TotalEstimatedCost USD"
Write-Host "Total Estimated Annual Cost: $($TotalEstimatedCost * 12) USD"
