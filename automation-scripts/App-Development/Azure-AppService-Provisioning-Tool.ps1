<#
.SYNOPSIS
    Manage App Services

.DESCRIPTION
    Manage App Services
    Author: Wes Ellis (wes@wesellis.com)#>
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
Write-Host "Provisioning App Service: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "App Service Plan: $PlanName"
Write-Host "Location: $Location"
Write-Host "Runtime: $Runtime $RuntimeVersion"
Write-Host "HTTPS Only: $HttpsOnly"
# Create the App Service
$params = @{
    ErrorAction = "Stop"
    Location = $Location
    ResourceGroupName = $ResourceGroupName
    Name = $AppName
    AppServicePlan = $PlanName
}
$WebApp @params
Write-Host "App Service created: $($WebApp.DefaultHostName)"
# Configure runtime stack
if ($Runtime -eq "DOTNET") {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -NetFrameworkVersion "v$RuntimeVersion"
}
# Enable HTTPS only
if ($HttpsOnly) {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -HttpsOnly $true
    Write-Host "HTTPS-only enforcement enabled"
}
# Add app settings if provided
if ($AppSettings.Count -gt 0) {
    Write-Host "`nConfiguring App Settings:"
    foreach ($Setting in $AppSettings.GetEnumerator()) {
        Write-Host "  $($Setting.Key): $($Setting.Value)"
    }
    Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -AppSettings $AppSettings
}
Write-Host "`nApp Service $AppName provisioned successfully"
Write-Host "URL: https://$($WebApp.DefaultHostName)"
Write-Host "State: $($WebApp.State)"
Write-Host "`nApp Service provisioning completed at $(Get-Date)"

