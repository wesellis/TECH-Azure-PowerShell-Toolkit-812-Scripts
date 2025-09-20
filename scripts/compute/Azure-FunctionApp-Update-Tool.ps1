#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Function Apps

.DESCRIPTION
    Manage Function Apps
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName
)
# Get current Function App
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Host "Function App: $($FunctionApp.Name)"
Write-Host "Current Resource Group: $($FunctionApp.ResourceGroupName)"
Write-Host "Current Location: $($FunctionApp.Location)"
Write-Host "Current Runtime: $($FunctionApp.RuntimeVersion)"
# Update the Function App
if ($PlanName) {
    Write-Host "Updating App Service Plan to: $PlanName"
    Set-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName -AppServicePlan $PlanName
    Write-Host "Function App $AppName updated with new plan: $PlanName"
} else {
    Write-Host "No plan specified - displaying current configuration only"
}

