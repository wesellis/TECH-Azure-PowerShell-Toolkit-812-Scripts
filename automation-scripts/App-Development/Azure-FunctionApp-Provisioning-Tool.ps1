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
    [string]$PlanName,
    [string]$Location,
    [string]$Runtime = "PowerShell",
    [string]$RuntimeVersion = "7.2",
    [string]$StorageAccountName
)

#region Functions

Write-Information "Provisioning Function App: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "App Service Plan: $PlanName"
Write-Information "Location: $Location"
Write-Information "Runtime: $Runtime $RuntimeVersion"

# Create the Function App
$params = @{
    ResourceGroupName = $ResourceGroupName
    Name = $AppName
    RuntimeVersion = $RuntimeVersion
    AppServicePlan = $PlanName
    Runtime = $Runtime
    Location = $Location
    ErrorAction = "Stop"
}
$FunctionApp @params

if ($StorageAccountName) {
    Write-Information "Storage Account: $StorageAccountName"
}

Write-Information "Function App $AppName provisioned successfully"
Write-Information "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Information "State: $($FunctionApp.State)"


#endregion
