# ============================================================================
# Script Name: Azure App Service Health Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure App Service health, performance metrics, and configuration status
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AppName
)

Write-Host "Monitoring App Service: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get App Service details
$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Host "App Service Information:"
Write-Host "  Name: $($WebApp.Name)"
Write-Host "  State: $($WebApp.State)"
Write-Host "  Location: $($WebApp.Location)"
Write-Host "  Default Hostname: $($WebApp.DefaultHostName)"
Write-Host "  Repository Site Name: $($WebApp.RepositorySiteName)"
Write-Host "  App Service Plan: $($WebApp.ServerFarmId.Split('/')[-1])"
Write-Host "  .NET Framework Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Host "  PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Host "  Platform Architecture: $($WebApp.SiteConfig.Use32BitWorkerProcess)"

# Get app settings count
$AppSettingsCount = if ($WebApp.SiteConfig.AppSettings) { $WebApp.SiteConfig.AppSettings.Count } else { 0 }
Write-Host "  App Settings Count: $AppSettingsCount"

# Check if HTTPS only is enabled
Write-Host "  HTTPS Only: $($WebApp.HttpsOnly)"

# Get deployment slots
$Slots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction SilentlyContinue
if ($Slots) {
    Write-Host "  Deployment Slots: $($Slots.Count)"
    foreach ($Slot in $Slots) {
        Write-Host "    - $($Slot.Name) [$($Slot.State)]"
    }
} else {
    Write-Host "  Deployment Slots: 0"
}

Write-Host "`nApp Service monitoring completed at $(Get-Date)"
