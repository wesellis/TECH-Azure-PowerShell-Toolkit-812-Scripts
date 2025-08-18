<#
.SYNOPSIS
    Azure Resourcegroup Cost Calculator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Resourcegroup Cost Calculator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [string]$WEResourceGroupName
)

Write-WELog " Calculating estimated costs for Resource Group: $WEResourceGroupName" " INFO"

$WEResources = Get-AzResource -ResourceGroupName $WEResourceGroupName

$WETotalEstimatedCost = 0
$WECostBreakdown = @()

foreach ($WEResource in $WEResources) {
    $WEEstimatedMonthlyCost = 0
    
    switch ($WEResource.ResourceType) {
        " Microsoft.Compute/virtualMachines" { $WEEstimatedMonthlyCost = 73.00 }
        " Microsoft.Storage/storageAccounts" { $WEEstimatedMonthlyCost = 25.00 }
        " Microsoft.Sql/servers/databases" { $WEEstimatedMonthlyCost = 200.00 }
        " Microsoft.Network/applicationGateways" { $WEEstimatedMonthlyCost = 125.00 }
        " Microsoft.ContainerInstance/containerGroups" {;  $WEEstimatedMonthlyCost = 50.00 }
        default {;  $WEEstimatedMonthlyCost = 10.00 }
    }
    
    $WECostBreakdown = $WECostBreakdown + [PSCustomObject]@{
        ResourceName = $WEResource.Name
        ResourceType = $WEResource.ResourceType
        EstimatedMonthlyCost = $WEEstimatedMonthlyCost
    }
    
   ;  $WETotalEstimatedCost = $WETotalEstimatedCost + $WEEstimatedMonthlyCost
}

Write-WELog " `nCost Breakdown:" " INFO"
foreach ($WEItem in $WECostBreakdown) {
    Write-WELog "  $($WEItem.ResourceName): $($WEItem.EstimatedMonthlyCost) USD/month" " INFO"
}

Write-WELog " `nTotal Estimated Monthly Cost: $WETotalEstimatedCost USD" " INFO"
Write-WELog " Total Estimated Annual Cost: $($WETotalEstimatedCost * 12) USD" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
