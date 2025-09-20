<#
.SYNOPSIS
    Azure Functionapp Performance Monitor

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$AppName
)
Write-Host "Monitoring Function App: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host " ============================================"
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Host "Function App Information:"
Write-Host "Name: $($FunctionApp.Name)"
Write-Host "State: $($FunctionApp.State)"
Write-Host "Location: $($FunctionApp.Location)"
Write-Host "Default Hostname: $($FunctionApp.DefaultHostName)"
Write-Host "Kind: $($FunctionApp.Kind)"
Write-Host "App Service Plan: $($FunctionApp.AppServicePlan)"
Write-Host " `nRuntime Configuration:"
Write-Host "Runtime: $($FunctionApp.Runtime)"
Write-Host "Runtime Version: $($FunctionApp.RuntimeVersion)"
Write-Host "OS Type: $($FunctionApp.OSType)"
$AppSettings = $FunctionApp.ApplicationSettings
if ($AppSettings) {
    Write-Host " `nApplication Settings: $($AppSettings.Count) configured"
    # List non-sensitive setting keys
$SafeSettings = $AppSettings.Keys | Where-Object {
        $_ -notlike " *KEY*" -and
        $_ -notlike " *SECRET*" -and
        $_ -notlike " *PASSWORD*" -and
        $_ -notlike " *CONNECTION*"
    }
    if ($SafeSettings) {
        Write-Host "Non-sensitive settings: $($SafeSettings -join ', ')"
    }
}
Write-Host " `nSecurity:"
Write-Host "HTTPS Only: $($FunctionApp.HttpsOnly)"
try {
    # Note: This would require additional permissions and might not always be accessible
    Write-Host " `nFunctions: Use Azure Portal or Azure CLI for  function metrics"
} catch {
    Write-Host " `nFunctions: Unable to enumerate (check permissions)"
}
Write-Host " `nFunction App monitoring completed at $(Get-Date)"

