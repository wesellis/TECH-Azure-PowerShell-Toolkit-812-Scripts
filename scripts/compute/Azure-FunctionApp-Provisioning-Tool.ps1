#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Functions

<#`n.SYNOPSIS
    Manage Function Apps

.DESCRIPTION
    Manage Function Apps
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName,
    [string]$Location,
    [string]$Runtime = "PowerShell",
    [string]$RuntimeVersion = "7.2",
    [string]$StorageAccountName
)
Write-Host "Provisioning Function App: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "App Service Plan: $PlanName"
Write-Host "Location: $Location"
Write-Host "Runtime: $Runtime $RuntimeVersion"
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
$FunctionApp = New-AzFunctionApp @params
if ($StorageAccountName) {
    Write-Host "Storage Account: $StorageAccountName"
}
Write-Host "Function App $AppName provisioned successfully"
Write-Host "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Host "State: $($FunctionApp.State)"

