# ============================================================================
# Script Name: Azure Function App Setting Manager
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Adds or updates application settings for Azure Function App
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
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
    Write-Host "  Added/Updated: $($Setting.Key)"
}

# Update Function App
Update-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -AppSetting $ExistingSettings

Write-Host "✅ Function App settings updated successfully!"
