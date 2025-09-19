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
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$AppSettings
)

#region Functions

Write-Information "Updating Function App settings: $FunctionAppName"

$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName

# Get existing settings
$ExistingSettings = $FunctionApp.ApplicationSettings
if (-not $ExistingSettings) { $ExistingSettings = @{} }

# Add new settings
foreach ($Setting in $AppSettings.GetEnumerator()) {
    $ExistingSettings[$Setting.Key] = $Setting.Value
    Write-Information "  Added/Updated: $($Setting.Key)"
}

# Update Function App
Update-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -AppSetting $ExistingSettings

Write-Information " Function App settings updated successfully!"


#endregion
