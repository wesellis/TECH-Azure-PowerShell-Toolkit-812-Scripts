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
    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName
)

#region Functions

# Get current Function App
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Information "Function App: $($FunctionApp.Name)"
Write-Information "Current Resource Group: $($FunctionApp.ResourceGroupName)"
Write-Information "Current Location: $($FunctionApp.Location)"
Write-Information "Current Runtime: $($FunctionApp.RuntimeVersion)"

# Update the Function App
if ($PlanName) {
    Write-Information "Updating App Service Plan to: $PlanName"
    Set-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName -AppServicePlan $PlanName
    Write-Information "Function App $AppName updated with new plan: $PlanName"
} else {
    Write-Information "No plan specified - displaying current configuration only"
}


#endregion
