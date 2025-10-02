#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage App Services

.DESCRIPTION
    Manage App Services
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AppName
)
Write-Output "Retrieving configuration for App Service: $AppName"
$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Output "`nApp Service Configuration:"
Write-Output "Name: $($WebApp.Name)"
Write-Output "State: $($WebApp.State)"
Write-Output "Default Hostname: $($WebApp.DefaultHostName)"
Write-Output "Runtime Stack: $($WebApp.SiteConfig.LinuxFxVersion)"
Write-Output "  .NET Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Output "PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Output "HTTPS Only: $($WebApp.HttpsOnly)"
if ($WebApp.SiteConfig.AppSettings) {
    Write-Output "`nApplication Settings Count: $($WebApp.SiteConfig.AppSettings.Count)"`n}
