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
    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName,
    [string]$Location,
    [string]$Runtime = "DOTNET",
    [string]$RuntimeVersion = "6.0",
    [bool]$HttpsOnly = $true,
    [hashtable]$AppSettings = @{}
)

#region Functions

Write-Information "Provisioning App Service: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "App Service Plan: $PlanName"
Write-Information "Location: $Location"
Write-Information "Runtime: $Runtime $RuntimeVersion"
Write-Information "HTTPS Only: $HttpsOnly"

# Create the App Service
$params = @{
    ErrorAction = "Stop"
    Location = $Location
    ResourceGroupName = $ResourceGroupName
    Name = $AppName
    AppServicePlan = $PlanName
}
$WebApp @params

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


#endregion
