<#
.SYNOPSIS
    Azure Resourcegroup Cost Calculator

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter(Mandatory)]
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
        "Microsoft.ContainerInstance/containerGroups" {;  $EstimatedMonthlyCost = 50.00 }
        default {;  $EstimatedMonthlyCost = 10.00 }
    }
    $CostBreakdown = $CostBreakdown + [PSCustomObject]@{
        ResourceName = $Resource.Name
        ResourceType = $Resource.ResourceType
        EstimatedMonthlyCost = $EstimatedMonthlyCost
    }
$TotalEstimatedCost = $TotalEstimatedCost + $EstimatedMonthlyCost
}
Write-Host " `nCost Breakdown:"
foreach ($Item in $CostBreakdown) {
    Write-Host "  $($Item.ResourceName): $($Item.EstimatedMonthlyCost) USD/month"
}
Write-Host " `nTotal Estimated Monthly Cost: $TotalEstimatedCost USD"
Write-Host "Total Estimated Annual Cost: $($TotalEstimatedCost * 12) USD"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

