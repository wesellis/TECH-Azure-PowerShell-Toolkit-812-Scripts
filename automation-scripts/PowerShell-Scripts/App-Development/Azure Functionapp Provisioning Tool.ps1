<#
.SYNOPSIS
    Azure Functionapp Provisioning Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
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
Write-Host "Provisioning Function App: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "App Service Plan: $PlanName"
Write-Host "Location: $Location"
Write-Host "Runtime: $Runtime $RuntimeVersion"
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
    Write-Host "Storage Account: $StorageAccountName"
}
Write-Host "Function App $AppName provisioned successfully"
Write-Host "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Host "State: $($FunctionApp.State)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n