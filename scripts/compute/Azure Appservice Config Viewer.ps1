#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Appservice Config Viewer

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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AppName
)
Write-Output "Retrieving configuration for App Service: $AppName"
    $WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Output " `nApp Service Configuration:"
Write-Output "Name: $($WebApp.Name)"
Write-Output "State: $($WebApp.State)"
Write-Output "Default Hostname: $($WebApp.DefaultHostName)"
Write-Output "Runtime Stack: $($WebApp.SiteConfig.LinuxFxVersion)"
Write-Output "  .NET Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Output "PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Output "HTTPS Only: $($WebApp.HttpsOnly)"
if ($WebApp.SiteConfig.AppSettings) {
    Write-Output " `nApplication Settings Count: $($WebApp.SiteConfig.AppSettings.Count)"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
