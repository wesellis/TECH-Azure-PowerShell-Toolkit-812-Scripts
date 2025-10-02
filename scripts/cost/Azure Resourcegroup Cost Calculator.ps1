#Requires -Version 7.4
#Requires -Modules Az.Resources

<#.SYNOPSIS
    Azure Resourcegroup Cost Calculator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName
)
Write-Output "Calculating estimated costs for Resource Group: $ResourceGroupName"
$Resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    [string]$TotalEstimatedCost = 0
    [string]$CostBreakdown = @()
foreach ($Resource in $Resources) {
    [string]$EstimatedMonthlyCost = 0
    switch ($Resource.ResourceType) {
        "Microsoft.Compute/virtualMachines" { $EstimatedMonthlyCost = 73.00 }
        "Microsoft.Storage/storageAccounts" { $EstimatedMonthlyCost = 25.00 }
        "Microsoft.Sql/servers/databases" { $EstimatedMonthlyCost = 200.00 }
        "Microsoft.Network/applicationGateways" { $EstimatedMonthlyCost = 125.00 }
        "Microsoft.ContainerInstance/containerGroups" {;  $EstimatedMonthlyCost = 50.00 }
        default {;  $EstimatedMonthlyCost = 10.00 }
    }
    [string]$CostBreakdown = $CostBreakdown + [PSCustomObject]@{
        ResourceName = $Resource.Name
        ResourceType = $Resource.ResourceType
        EstimatedMonthlyCost = $EstimatedMonthlyCost
    }
    [string]$TotalEstimatedCost = $TotalEstimatedCost + $EstimatedMonthlyCost
}
Write-Output " `nCost Breakdown:"
foreach ($Item in $CostBreakdown) {
    Write-Output "  $($Item.ResourceName): $($Item.EstimatedMonthlyCost) USD/month"
}
Write-Output " `nTotal Estimated Monthly Cost: $TotalEstimatedCost USD"
Write-Output "Total Estimated Annual Cost: $($TotalEstimatedCost * 12) USD"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
