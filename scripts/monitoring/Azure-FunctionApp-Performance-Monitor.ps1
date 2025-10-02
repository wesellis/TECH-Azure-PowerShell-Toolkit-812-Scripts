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
    [string]$AppName
)
Write-Output "Monitoring Function App: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Output "Function App Information:"
Write-Output "Name: $($FunctionApp.Name)"
Write-Output "State: $($FunctionApp.State)"
Write-Output "Location: $($FunctionApp.Location)"
Write-Output "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Output "Kind: $($FunctionApp.Kind)"
Write-Output "App Service Plan: $($FunctionApp.AppServicePlan)"
Write-Output "`nRuntime Configuration:"
Write-Output "Runtime: $($FunctionApp.Runtime)"
Write-Output "Runtime Version: $($FunctionApp.RuntimeVersion)"
Write-Output "OS Type: $($FunctionApp.OSType)"
$AppSettings = $FunctionApp.ApplicationSettings
if ($AppSettings) {
    Write-Output "`nApplication Settings: $($AppSettings.Count) configured"
    $SafeSettings = $AppSettings.Keys | Where-Object {
        $_ -notlike "*KEY*" -and
        $_ -notlike "*SECRET*" -and
        $_ -notlike "*PASSWORD*" -and
        $_ -notlike "*CONNECTION*"
    }
    if ($SafeSettings) {
        Write-Output "Non-sensitive settings: $($SafeSettings -join ', ')"
    }
}
Write-Output "`nSecurity:"
Write-Output "HTTPS Only: $($FunctionApp.HttpsOnly)"
try {
    Write-Output "`nFunctions: Use Azure Portal or Azure CLI for  function metrics"
} catch {
    Write-Output "`nFunctions: Unable to enumerate (check permissions)"
}
Write-Output "`nFunction App monitoring completed at $(Get-Date)"



