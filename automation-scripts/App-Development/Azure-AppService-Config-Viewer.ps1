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
