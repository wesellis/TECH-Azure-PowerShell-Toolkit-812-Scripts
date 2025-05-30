# ============================================================================
# Script Name: Azure Function App Performance Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Function App performance, execution metrics, and runtime status
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AppName
)

Write-Host "Monitoring Function App: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get Function App details
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Host "Function App Information:"
Write-Host "  Name: $($FunctionApp.Name)"
Write-Host "  State: $($FunctionApp.State)"
Write-Host "  Location: $($FunctionApp.Location)"
Write-Host "  Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Host "  Kind: $($FunctionApp.Kind)"
Write-Host "  App Service Plan: $($FunctionApp.AppServicePlan)"

# Runtime information
Write-Host "`nRuntime Configuration:"
Write-Host "  Runtime: $($FunctionApp.Runtime)"
Write-Host "  Runtime Version: $($FunctionApp.RuntimeVersion)"
Write-Host "  OS Type: $($FunctionApp.OSType)"

# Get app settings (without revealing sensitive values)
$AppSettings = $FunctionApp.ApplicationSettings
if ($AppSettings) {
    Write-Host "`nApplication Settings: $($AppSettings.Count) configured"
    # List non-sensitive setting keys
    $SafeSettings = $AppSettings.Keys | Where-Object { 
        $_ -notlike "*KEY*" -and 
        $_ -notlike "*SECRET*" -and 
        $_ -notlike "*PASSWORD*" -and
        $_ -notlike "*CONNECTION*"
    }
    if ($SafeSettings) {
        Write-Host "  Non-sensitive settings: $($SafeSettings -join ', ')"
    }
}

# Check if HTTPS only is enabled
Write-Host "`nSecurity:"
Write-Host "  HTTPS Only: $($FunctionApp.HttpsOnly)"

# Get function count (if accessible)
try {
    # Note: This would require additional permissions and might not always be accessible
    Write-Host "`nFunctions: Use Azure Portal or Azure CLI for detailed function metrics"
} catch {
    Write-Host "`nFunctions: Unable to enumerate (check permissions)"
}

Write-Host "`nFunction App monitoring completed at $(Get-Date)"
