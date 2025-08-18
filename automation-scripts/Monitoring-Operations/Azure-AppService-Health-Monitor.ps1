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

Write-Information "Monitoring App Service: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get App Service details
$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Information "App Service Information:"
Write-Information "  Name: $($WebApp.Name)"
Write-Information "  State: $($WebApp.State)"
Write-Information "  Location: $($WebApp.Location)"
Write-Information "  Default Hostname: $($WebApp.DefaultHostName)"
Write-Information "  Repository Site Name: $($WebApp.RepositorySiteName)"
Write-Information "  App Service Plan: $($WebApp.ServerFarmId.Split('/')[-1])"
Write-Information "  .NET Framework Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Information "  PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Information "  Platform Architecture: $($WebApp.SiteConfig.Use32BitWorkerProcess)"

# Get app settings count
$AppSettingsCount = if ($WebApp.SiteConfig.AppSettings) { $WebApp.SiteConfig.AppSettings.Count } else { 0 }
Write-Information "  App Settings Count: $AppSettingsCount"

# Check if HTTPS only is enabled
Write-Information "  HTTPS Only: $($WebApp.HttpsOnly)"

# Get deployment slots
$Slots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction SilentlyContinue
if ($Slots) {
    Write-Information "  Deployment Slots: $($Slots.Count)"
    foreach ($Slot in $Slots) {
        Write-Information "    - $($Slot.Name) [$($Slot.State)]"
    }
} else {
    Write-Information "  Deployment Slots: 0"
}

Write-Information "`nApp Service monitoring completed at $(Get-Date)"
