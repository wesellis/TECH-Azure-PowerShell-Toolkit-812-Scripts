<#
.SYNOPSIS
    We Enhanced Azure Appservice Health Monitor

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WEAppName
)

Write-WELog " Monitoring App Service: $WEAppName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WEWebApp = Get-AzWebApp -ResourceGroupName $WEResourceGroupName -Name $WEAppName

Write-WELog " App Service Information:" " INFO"
Write-WELog "  Name: $($WEWebApp.Name)" " INFO"
Write-WELog "  State: $($WEWebApp.State)" " INFO"
Write-WELog "  Location: $($WEWebApp.Location)" " INFO"
Write-WELog "  Default Hostname: $($WEWebApp.DefaultHostName)" " INFO"
Write-WELog "  Repository Site Name: $($WEWebApp.RepositorySiteName)" " INFO"
Write-WELog "  App Service Plan: $($WEWebApp.ServerFarmId.Split('/')[-1])" " INFO"
Write-WELog "  .NET Framework Version: $($WEWebApp.SiteConfig.NetFrameworkVersion)" " INFO"
Write-WELog "  PHP Version: $($WEWebApp.SiteConfig.PhpVersion)" " INFO"
Write-WELog "  Platform Architecture: $($WEWebApp.SiteConfig.Use32BitWorkerProcess)" " INFO"


$WEAppSettingsCount = if ($WEWebApp.SiteConfig.AppSettings) { $WEWebApp.SiteConfig.AppSettings.Count } else { 0 }
Write-WELog "  App Settings Count: $WEAppSettingsCount" " INFO"


Write-WELog "  HTTPS Only: $($WEWebApp.HttpsOnly)" " INFO"

; 
$WESlots = Get-AzWebAppSlot -ResourceGroupName $WEResourceGroupName -Name $WEAppName -ErrorAction SilentlyContinue
if ($WESlots) {
    Write-WELog "  Deployment Slots: $($WESlots.Count)" " INFO"
    foreach ($WESlot in $WESlots) {
        Write-WELog "    - $($WESlot.Name) [$($WESlot.State)]" " INFO"
    }
} else {
    Write-WELog "  Deployment Slots: 0" " INFO"
}

Write-WELog " `nApp Service monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
