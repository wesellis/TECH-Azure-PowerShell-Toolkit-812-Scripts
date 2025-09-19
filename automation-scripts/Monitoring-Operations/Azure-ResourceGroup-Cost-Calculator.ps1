#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

#region Functions

Write-Information "Calculating estimated costs for Resource Group: $ResourceGroupName"

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

Write-Information "`nCost Breakdown:"
foreach ($Item in $CostBreakdown) {
    Write-Information "  $($Item.ResourceName): $($Item.EstimatedMonthlyCost) USD/month"
}

Write-Information "`nTotal Estimated Monthly Cost: $TotalEstimatedCost USD"
Write-Information "Total Estimated Annual Cost: $($TotalEstimatedCost * 12) USD"


#endregion
