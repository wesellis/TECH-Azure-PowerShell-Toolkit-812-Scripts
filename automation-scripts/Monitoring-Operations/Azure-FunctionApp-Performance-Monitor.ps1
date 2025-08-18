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

Write-Information "Monitoring Function App: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get Function App details
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName

Write-Information "Function App Information:"
Write-Information "  Name: $($FunctionApp.Name)"
Write-Information "  State: $($FunctionApp.State)"
Write-Information "  Location: $($FunctionApp.Location)"
Write-Information "  Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Information "  Kind: $($FunctionApp.Kind)"
Write-Information "  App Service Plan: $($FunctionApp.AppServicePlan)"

# Runtime information
Write-Information "`nRuntime Configuration:"
Write-Information "  Runtime: $($FunctionApp.Runtime)"
Write-Information "  Runtime Version: $($FunctionApp.RuntimeVersion)"
Write-Information "  OS Type: $($FunctionApp.OSType)"

# Get app settings (without revealing sensitive values)
$AppSettings = $FunctionApp.ApplicationSettings
if ($AppSettings) {
    Write-Information "`nApplication Settings: $($AppSettings.Count) configured"
    # List non-sensitive setting keys
    $SafeSettings = $AppSettings.Keys | Where-Object { 
        $_ -notlike "*KEY*" -and 
        $_ -notlike "*SECRET*" -and 
        $_ -notlike "*PASSWORD*" -and
        $_ -notlike "*CONNECTION*"
    }
    if ($SafeSettings) {
        Write-Information "  Non-sensitive settings: $($SafeSettings -join ', ')"
    }
}

# Check if HTTPS only is enabled
Write-Information "`nSecurity:"
Write-Information "  HTTPS Only: $($FunctionApp.HttpsOnly)"

# Get function count (if accessible)
try {
    # Note: This would require additional permissions and might not always be accessible
    Write-Information "`nFunctions: Use Azure Portal or Azure CLI for detailed function metrics"
} catch {
    Write-Information "`nFunctions: Unable to enumerate (check permissions)"
}

Write-Information "`nFunction App monitoring completed at $(Get-Date)"
