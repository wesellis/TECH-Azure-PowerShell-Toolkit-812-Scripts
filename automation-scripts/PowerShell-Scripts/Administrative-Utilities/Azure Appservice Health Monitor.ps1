#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Appservice Health Monitor

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
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
Write-Host "Monitoring App Service: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host " ============================================"
$WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
Write-Host "App Service Information:"
Write-Host "Name: $($WebApp.Name)"
Write-Host "State: $($WebApp.State)"
Write-Host "Location: $($WebApp.Location)"
Write-Host "Default Hostname: $($WebApp.DefaultHostName)"
Write-Host "Repository Site Name: $($WebApp.RepositorySiteName)"
Write-Host "App Service Plan: $($WebApp.ServerFarmId.Split('/')[-1])"
Write-Host "  .NET Framework Version: $($WebApp.SiteConfig.NetFrameworkVersion)"
Write-Host "PHP Version: $($WebApp.SiteConfig.PhpVersion)"
Write-Host "Platform Architecture: $($WebApp.SiteConfig.Use32BitWorkerProcess)"
$AppSettingsCount = if ($WebApp.SiteConfig.AppSettings) { $WebApp.SiteConfig.AppSettings.Count } else { 0 }
Write-Host "App Settings Count: $AppSettingsCount"
Write-Host "HTTPS Only: $($WebApp.HttpsOnly)"
$Slots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction SilentlyContinue
if ($Slots) {
    Write-Host "Deployment Slots: $($Slots.Count)"
    foreach ($Slot in $Slots) {
        Write-Host "    - $($Slot.Name) [$($Slot.State)]"
    }
} else {
    Write-Host "Deployment Slots: 0"
}
Write-Host " `nApp Service monitoring completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

