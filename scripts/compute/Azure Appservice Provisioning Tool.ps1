#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Appservice Provisioning Tool

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
    [string]$Runtime = "DOTNET" ,
    [string]$RuntimeVersion = " 6.0" ,
    [bool]$HttpsOnly = $true,
    [hashtable]$AppSettings = @{}
)
Write-Output "Provisioning App Service: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "App Service Plan: $PlanName"
Write-Output "Location: $Location"
Write-Output "Runtime: $Runtime $RuntimeVersion"
Write-Output "HTTPS Only: $HttpsOnly"
    $params = @{
    ErrorAction = "Stop"
    Location = $Location
    ResourceGroupName = $ResourceGroupName
    Name = $AppName
    AppServicePlan = $PlanName
}
    [string]$WebApp @params
Write-Output "App Service created: $($WebApp.DefaultHostName)"
if ($Runtime -eq "DOTNET" ) {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -NetFrameworkVersion " v$RuntimeVersion"
}
if ($HttpsOnly) {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -HttpsOnly $true
    Write-Output "HTTPS-only enforcement enabled"
}
if ($AppSettings.Count -gt 0) {
    Write-Output " `nConfiguring App Settings:"
    foreach ($Setting in $AppSettings.GetEnumerator()) {
        Write-Output "  $($Setting.Key): $($Setting.Value)"
    }
    Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -AppSettings $AppSettings
}
Write-Output " `nApp Service $AppName provisioned successfully"
Write-Output "URL: https://$($WebApp.DefaultHostName)"
Write-Output "State: $($WebApp.State)"
Write-Output " `nApp Service provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
