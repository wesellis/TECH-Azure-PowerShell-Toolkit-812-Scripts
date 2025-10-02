#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Function Apps

.DESCRIPTION
    Manage Function Apps
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$FunctionAppName,
    [Parameter(Mandatory)]
    [hashtable]$AppSettings
)
Write-Output "Updating Function App settings: $FunctionAppName"
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName
$ExistingSettings = $FunctionApp.ApplicationSettings
if (-not $ExistingSettings) { $ExistingSettings = @{} }
foreach ($Setting in $AppSettings.GetEnumerator()) {
    $ExistingSettings[$Setting.Key] = $Setting.Value
    Write-Output "Added/Updated: $($Setting.Key)"
}
Update-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -AppSetting $ExistingSettings
Write-Output "Function App settings updated successfully!"



