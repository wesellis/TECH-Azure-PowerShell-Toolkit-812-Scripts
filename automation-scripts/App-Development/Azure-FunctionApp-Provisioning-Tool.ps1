# ============================================================================
# Script Name: Azure Function App Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Function Apps with runtime and hosting configurations
# ============================================================================

param (
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
$FunctionApp = New-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $AppName `
    -AppServicePlan $PlanName `
    -Location $Location `
    -Runtime $Runtime `
    -RuntimeVersion $RuntimeVersion

if ($StorageAccountName) {
    Write-Host "Storage Account: $StorageAccountName"
}

Write-Host "Function App $AppName provisioned successfully"
Write-Host "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Host "State: $($FunctionApp.State)"
