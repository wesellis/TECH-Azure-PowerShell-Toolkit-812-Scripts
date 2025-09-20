#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Appservice Config Viewer

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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AppName
)
Write-Host "Retrieving configuration for App Service: $AppName"
$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Host " `nApp Service Configuration:"
Write-Host "Name: $($WebApp.Name)"
Write-Host "State: $($WebApp.State)"
Write-Host "Default Hostname: $($WebApp.DefaultHostName)"
Write-Host "Runtime Stack: $($WebApp.SiteConfig.LinuxFxVersion)"
Write-Host "  .NET Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Host "PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Host "HTTPS Only: $($WebApp.HttpsOnly)"
if ($WebApp.SiteConfig.AppSettings) {
    Write-Host " `nApplication Settings Count: $($WebApp.SiteConfig.AppSettings.Count)"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

