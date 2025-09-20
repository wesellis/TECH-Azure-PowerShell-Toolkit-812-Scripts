<#
.SYNOPSIS
    Manage App Services

.DESCRIPTION
    Manage App Services
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AppName
)
Write-Host "Retrieving configuration for App Service: $AppName"
$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Host "`nApp Service Configuration:"
Write-Host "Name: $($WebApp.Name)"
Write-Host "State: $($WebApp.State)"
Write-Host "Default Hostname: $($WebApp.DefaultHostName)"
Write-Host "Runtime Stack: $($WebApp.SiteConfig.LinuxFxVersion)"
Write-Host "  .NET Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Host "PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Host "HTTPS Only: $($WebApp.HttpsOnly)"
if ($WebApp.SiteConfig.AppSettings) {
    Write-Host "`nApplication Settings Count: $($WebApp.SiteConfig.AppSettings.Count)"
}

