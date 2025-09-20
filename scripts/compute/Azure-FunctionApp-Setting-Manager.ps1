#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Function Apps

.DESCRIPTION
    Manage Function Apps
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$FunctionAppName,
    [Parameter(Mandatory)]
    [hashtable]$AppSettings
)
Write-Host "Updating Function App settings: $FunctionAppName"
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName
# Get existing settings
$ExistingSettings = $FunctionApp.ApplicationSettings
if (-not $ExistingSettings) { $ExistingSettings = @{} }
# Add new settings
foreach ($Setting in $AppSettings.GetEnumerator()) {
    $ExistingSettings[$Setting.Key] = $Setting.Value
    Write-Host "Added/Updated: $($Setting.Key)"
}
# Update Function App
Update-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -AppSetting $ExistingSettings
Write-Host "Function App settings updated successfully!"

