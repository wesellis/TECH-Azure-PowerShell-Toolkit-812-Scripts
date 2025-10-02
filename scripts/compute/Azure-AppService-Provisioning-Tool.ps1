#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage App Services

.DESCRIPTION
    Manage App Services
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$PlanName,
    [string]$Location,
    [string]$Runtime = "DOTNET",
    [string]$RuntimeVersion = "6.0",
    [bool]$HttpsOnly = $true,
    [hashtable]$AppSettings = @{}
)
Write-Output "Provisioning App Service: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "App Service Plan: $PlanName"
Write-Output "Location: $Location"
Write-Output "Runtime: $Runtime $RuntimeVersion"
Write-Output "HTTPS Only: $HttpsOnly"
$params = @{
    ErrorAction = "Stop"
    Location = $Location
    ResourceGroupName = $ResourceGroupName
    Name = $AppName
    AppServicePlan = $PlanName
}
$WebApp @params
Write-Output "App Service created: $($WebApp.DefaultHostName)"
if ($Runtime -eq "DOTNET") {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -NetFrameworkVersion "v$RuntimeVersion"
}
if ($HttpsOnly) {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -HttpsOnly $true
    Write-Output "HTTPS-only enforcement enabled"
}
if ($AppSettings.Count -gt 0) {
    Write-Output "`nConfiguring App Settings:"
    foreach ($Setting in $AppSettings.GetEnumerator()) {
        Write-Output "  $($Setting.Key): $($Setting.Value)"
    }
    Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -AppSettings $AppSettings
}
Write-Output "`nApp Service $AppName provisioned successfully"
Write-Output "URL: https://$($WebApp.DefaultHostName)"
Write-Output "State: $($WebApp.State)"
Write-Output "`nApp Service provisioning completed at $(Get-Date)"



