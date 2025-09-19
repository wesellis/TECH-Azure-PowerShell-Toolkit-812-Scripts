#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Appservice Config Viewer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Appservice Config Viewer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WEAppName
)

#region Functions

Write-WELog " Retrieving configuration for App Service: $WEAppName" " INFO"
; 
$WEWebApp = Get-AzWebApp -ResourceGroupName $WEResourceGroupName -Name $WEAppName

Write-WELog " `nApp Service Configuration:" " INFO"
Write-WELog "  Name: $($WEWebApp.Name)" " INFO"
Write-WELog "  State: $($WEWebApp.State)" " INFO"
Write-WELog "  Default Hostname: $($WEWebApp.DefaultHostName)" " INFO"
Write-WELog "  Runtime Stack: $($WEWebApp.SiteConfig.LinuxFxVersion)" " INFO"
Write-WELog "  .NET Version: $($WEWebApp.SiteConfig.NetFrameworkVersion)" " INFO"
Write-WELog "  PHP Version: $($WEWebApp.SiteConfig.PhpVersion)" " INFO"
Write-WELog "  HTTPS Only: $($WEWebApp.HttpsOnly)" " INFO"

if ($WEWebApp.SiteConfig.AppSettings) {
    Write-WELog " `nApplication Settings Count: $($WEWebApp.SiteConfig.AppSettings.Count)" " INFO"
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
