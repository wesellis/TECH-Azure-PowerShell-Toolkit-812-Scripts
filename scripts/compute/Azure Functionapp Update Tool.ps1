#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Functionapp Update Tool

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
    Write-Output "No plan specified - displaying current configuration only"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
