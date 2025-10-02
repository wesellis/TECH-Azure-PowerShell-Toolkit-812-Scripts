#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName
)
Write-Output "Calculating estimated costs for Resource Group: $ResourceGroupName"
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
Write-Output "`nCost Breakdown:"
foreach ($Item in $CostBreakdown) {
    Write-Output "  $($Item.ResourceName): $($Item.EstimatedMonthlyCost) USD/month"
}
Write-Output "`nTotal Estimated Monthly Cost: $TotalEstimatedCost USD"
Write-Output "Total Estimated Annual Cost: $($TotalEstimatedCost * 12) USD"



