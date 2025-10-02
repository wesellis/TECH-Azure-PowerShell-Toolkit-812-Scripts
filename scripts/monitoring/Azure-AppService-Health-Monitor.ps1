#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Monitor service health

.DESCRIPTION
    Monitor service health
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AppName
)
Write-Output "Monitoring App Service: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Output "App Service Information:"
Write-Output "Name: $($WebApp.Name)"
Write-Output "State: $($WebApp.State)"
Write-Output "Location: $($WebApp.Location)"
Write-Output "Default Hostname: $($WebApp.DefaultHostName)"
Write-Output "Repository Site Name: $($WebApp.RepositorySiteName)"
Write-Output "App Service Plan: $($WebApp.ServerFarmId.Split('/')[-1])"
Write-Output "  .NET Framework Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Output "PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Output "Platform Architecture: $($WebApp.SiteConfig.Use32BitWorkerProcess)"
$AppSettingsCount = if ($WebApp.SiteConfig.AppSettings) { $WebApp.SiteConfig.AppSettings.Count } else { 0 }
Write-Output "App Settings Count: $AppSettingsCount"
Write-Output "HTTPS Only: $($WebApp.HttpsOnly)"
$Slots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction SilentlyContinue
if ($Slots) {
    Write-Output "Deployment Slots: $($Slots.Count)"
    foreach ($Slot in $Slots) {
        Write-Output "    - $($Slot.Name) [$($Slot.State)]"
    }
} else {
    Write-Output "Deployment Slots: 0"
}
Write-Output "`nApp Service monitoring completed at $(Get-Date)"



