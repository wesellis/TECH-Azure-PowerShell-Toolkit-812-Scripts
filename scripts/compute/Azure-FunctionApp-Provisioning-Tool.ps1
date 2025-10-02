#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Functions

<#`n.SYNOPSIS
    Manage Function Apps

.DESCRIPTION
    Manage Function Apps
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName,
    [string]$Location,
    [string]$Runtime = "PowerShell",
    [string]$RuntimeVersion = "7.2",
    [string]$StorageAccountName
)
Write-Output "Provisioning Function App: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "App Service Plan: $PlanName"
Write-Output "Location: $Location"
Write-Output "Runtime: $Runtime $RuntimeVersion"
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
    Write-Output "Storage Account: $StorageAccountName"
}
Write-Output "Function App $AppName provisioned successfully"
Write-Output "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Output "State: $($FunctionApp.State)"



