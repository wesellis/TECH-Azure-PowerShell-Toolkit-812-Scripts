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

Write-Information "Provisioning Function App: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "App Service Plan: $PlanName"
Write-Information "Location: $Location"
Write-Information "Runtime: $Runtime $RuntimeVersion"

# Create the Function App
$FunctionApp = New-AzFunctionApp -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $AppName `
    -AppServicePlan $PlanName `
    -Location $Location `
    -Runtime $Runtime `
    -RuntimeVersion $RuntimeVersion

if ($StorageAccountName) {
    Write-Information "Storage Account: $StorageAccountName"
}

Write-Information "Function App $AppName provisioned successfully"
Write-Information "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Information "State: $($FunctionApp.State)"
