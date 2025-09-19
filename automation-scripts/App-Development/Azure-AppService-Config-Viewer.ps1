#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppName
)

#region Functions

Write-Information "Retrieving configuration for App Service: $AppName"

$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Information "`nApp Service Configuration:"
Write-Information "  Name: $($WebApp.Name)"
Write-Information "  State: $($WebApp.State)"
Write-Information "  Default Hostname: $($WebApp.DefaultHostName)"
Write-Information "  Runtime Stack: $($WebApp.SiteConfig.LinuxFxVersion)"
Write-Information "  .NET Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Information "  PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Information "  HTTPS Only: $($WebApp.HttpsOnly)"

if ($WebApp.SiteConfig.AppSettings) {
    Write-Information "`nApplication Settings Count: $($WebApp.SiteConfig.AppSettings.Count)"
}


#endregion
