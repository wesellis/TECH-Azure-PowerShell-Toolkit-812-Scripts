# ============================================================================
# Script Name: Azure App Service Configuration Viewer
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Displays configuration settings for Azure App Service
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppName
)

Write-Host "Retrieving configuration for App Service: $AppName"

$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Host "`nApp Service Configuration:"
Write-Host "  Name: $($WebApp.Name)"
Write-Host "  State: $($WebApp.State)"
Write-Host "  Default Hostname: $($WebApp.DefaultHostName)"
Write-Host "  Runtime Stack: $($WebApp.SiteConfig.LinuxFxVersion)"
Write-Host "  .NET Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Host "  PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Host "  HTTPS Only: $($WebApp.HttpsOnly)"

if ($WebApp.SiteConfig.AppSettings) {
    Write-Host "`nApplication Settings Count: $($WebApp.SiteConfig.AppSettings.Count)"
}
