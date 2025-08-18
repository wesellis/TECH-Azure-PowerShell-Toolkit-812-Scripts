# ============================================================================
# Script Name: Azure App Service Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure App Service web applications with custom configurations
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName,
    [string]$Location,
    [string]$Runtime = "DOTNET",
    [string]$RuntimeVersion = "6.0",
    [bool]$HttpsOnly = $true,
    [hashtable]$AppSettings = @{}
)

Write-Information "Provisioning App Service: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "App Service Plan: $PlanName"
Write-Information "Location: $Location"
Write-Information "Runtime: $Runtime $RuntimeVersion"
Write-Information "HTTPS Only: $HttpsOnly"

# Create the App Service
$WebApp = New-AzWebApp -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $AppName `
    -AppServicePlan $PlanName `
    -Location $Location

Write-Information "App Service created: $($WebApp.DefaultHostName)"

# Configure runtime stack
if ($Runtime -eq "DOTNET") {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -NetFrameworkVersion "v$RuntimeVersion"
}

# Enable HTTPS only
if ($HttpsOnly) {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -HttpsOnly $true
    Write-Information "HTTPS-only enforcement enabled"
}

# Add app settings if provided
if ($AppSettings.Count -gt 0) {
    Write-Information "`nConfiguring App Settings:"
    foreach ($Setting in $AppSettings.GetEnumerator()) {
        Write-Information "  $($Setting.Key): $($Setting.Value)"
    }
    Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -AppSettings $AppSettings
}

Write-Information "`nApp Service $AppName provisioned successfully"
Write-Information "URL: https://$($WebApp.DefaultHostName)"
Write-Information "State: $($WebApp.State)"

Write-Information "`nApp Service provisioning completed at $(Get-Date)"
