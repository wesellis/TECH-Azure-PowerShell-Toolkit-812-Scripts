#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Function Apps

.DESCRIPTION
    Manage Function Apps
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName
)
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Output "Function App: $($FunctionApp.Name)"
Write-Output "Current Resource Group: $($FunctionApp.ResourceGroupName)"
Write-Output "Current Location: $($FunctionApp.Location)"
Write-Output "Current Runtime: $($FunctionApp.RuntimeVersion)"
if ($PlanName) {
    Write-Output "Updating App Service Plan to: $PlanName"
    Set-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName -AppServicePlan $PlanName
    Write-Output "Function App $AppName updated with new plan: $PlanName"
} else {
    Write-Output "No plan specified - displaying current configuration only"`n}
