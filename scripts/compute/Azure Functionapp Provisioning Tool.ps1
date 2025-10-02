#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Functionapp Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
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
;
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PlanName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$Runtime = "PowerShell" ,
    [string]$RuntimeVersion = " 7.2" ,
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
    [string]$FunctionApp @params
if ($StorageAccountName) {
    Write-Output "Storage Account: $StorageAccountName"
}
Write-Output "Function App $AppName provisioned successfully"
Write-Output "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Output "State: $($FunctionApp.State)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
