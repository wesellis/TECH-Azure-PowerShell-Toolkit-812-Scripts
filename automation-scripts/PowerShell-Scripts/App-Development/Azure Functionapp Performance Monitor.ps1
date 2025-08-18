<#
.SYNOPSIS
    Azure Functionapp Performance Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Functionapp Performance Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WEAppName
)

Write-WELog " Monitoring Function App: $WEAppName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WEFunctionApp = Get-AzFunctionApp -ResourceGroupName $WEResourceGroupName -Name $WEAppName

Write-WELog " Function App Information:" " INFO"
Write-WELog "  Name: $($WEFunctionApp.Name)" " INFO"
Write-WELog "  State: $($WEFunctionApp.State)" " INFO"
Write-WELog "  Location: $($WEFunctionApp.Location)" " INFO"
Write-WELog "  Default Hostname: $($WEFunctionApp.DefaultHostName)" " INFO"
Write-WELog "  Kind: $($WEFunctionApp.Kind)" " INFO"
Write-WELog "  App Service Plan: $($WEFunctionApp.AppServicePlan)" " INFO"


Write-WELog " `nRuntime Configuration:" " INFO"
Write-WELog "  Runtime: $($WEFunctionApp.Runtime)" " INFO"
Write-WELog "  Runtime Version: $($WEFunctionApp.RuntimeVersion)" " INFO"
Write-WELog "  OS Type: $($WEFunctionApp.OSType)" " INFO"

; 
$WEAppSettings = $WEFunctionApp.ApplicationSettings
if ($WEAppSettings) {
    Write-WELog " `nApplication Settings: $($WEAppSettings.Count) configured" " INFO"
    # List non-sensitive setting keys
   ;  $WESafeSettings = $WEAppSettings.Keys | Where-Object { 
        $_ -notlike " *KEY*" -and 
        $_ -notlike " *SECRET*" -and 
        $_ -notlike " *PASSWORD*" -and
        $_ -notlike " *CONNECTION*"
    }
    if ($WESafeSettings) {
        Write-WELog "  Non-sensitive settings: $($WESafeSettings -join ', ')" " INFO"
    }
}


Write-WELog " `nSecurity:" " INFO"
Write-WELog "  HTTPS Only: $($WEFunctionApp.HttpsOnly)" " INFO"


try {
    # Note: This would require additional permissions and might not always be accessible
    Write-WELog " `nFunctions: Use Azure Portal or Azure CLI for detailed function metrics" " INFO"
} catch {
    Write-WELog " `nFunctions: Unable to enumerate (check permissions)" " INFO"
}

Write-WELog " `nFunction App monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================