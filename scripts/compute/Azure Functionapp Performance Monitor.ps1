#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Functionapp Performance Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$AppName
)
Write-Output "Monitoring Function App: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output " ============================================"
    $FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Output "Function App Information:"
Write-Output "Name: $($FunctionApp.Name)"
Write-Output "State: $($FunctionApp.State)"
Write-Output "Location: $($FunctionApp.Location)"
Write-Output "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Output "Kind: $($FunctionApp.Kind)"
Write-Output "App Service Plan: $($FunctionApp.AppServicePlan)"
Write-Output " `nRuntime Configuration:"
Write-Output "Runtime: $($FunctionApp.Runtime)"
Write-Output "Runtime Version: $($FunctionApp.RuntimeVersion)"
Write-Output "OS Type: $($FunctionApp.OSType)"
    [string]$AppSettings = $FunctionApp.ApplicationSettings
if ($AppSettings) {
    Write-Output " `nApplication Settings: $($AppSettings.Count) configured"
    [string]$SafeSettings = $AppSettings.Keys | Where-Object {
    [string]$_ -notlike " *KEY*" -and
    [string]$_ -notlike " *SECRET*" -and
    [string]$_ -notlike " *PASSWORD*" -and
    [string]$_ -notlike " *CONNECTION*"
    }
    if ($SafeSettings) {
        Write-Output "Non-sensitive settings: $($SafeSettings -join ', ')"
    }
}
Write-Output " `nSecurity:"
Write-Output "HTTPS Only: $($FunctionApp.HttpsOnly)"
try {
    Write-Output " `nFunctions: Use Azure Portal or Azure CLI for  function metrics"
} catch {
    Write-Output " `nFunctions: Unable to enumerate (check permissions)"
}
Write-Output " `nFunction App monitoring completed at $(Get-Date)"



