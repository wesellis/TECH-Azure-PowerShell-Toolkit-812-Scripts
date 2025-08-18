<#
.SYNOPSIS
    Azure Appservice Provisioning Tool

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
    We Enhanced Azure Appservice Provisioning Tool

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAppName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPlanName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WERuntime = " DOTNET" ,
    [string]$WERuntimeVersion = " 6.0" ,
    [bool]$WEHttpsOnly = $true,
    [hashtable]$WEAppSettings = @{}
)

Write-WELog " Provisioning App Service: $WEAppName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " App Service Plan: $WEPlanName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Runtime: $WERuntime $WERuntimeVersion" " INFO"
Write-WELog " HTTPS Only: $WEHttpsOnly" " INFO"

; 
$WEWebApp = New-AzWebApp -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEAppName `
    -AppServicePlan $WEPlanName `
    -Location $WELocation

Write-WELog " App Service created: $($WEWebApp.DefaultHostName)" " INFO"


if ($WERuntime -eq " DOTNET" ) {
    Set-AzWebApp -ResourceGroupName $WEResourceGroupName -Name $WEAppName -NetFrameworkVersion " v$WERuntimeVersion"
}


if ($WEHttpsOnly) {
    Set-AzWebApp -ResourceGroupName $WEResourceGroupName -Name $WEAppName -HttpsOnly $true
    Write-WELog " HTTPS-only enforcement enabled" " INFO"
}


if ($WEAppSettings.Count -gt 0) {
    Write-WELog " `nConfiguring App Settings:" " INFO"
    foreach ($WESetting in $WEAppSettings.GetEnumerator()) {
        Write-WELog "  $($WESetting.Key): $($WESetting.Value)" " INFO"
    }
    Set-AzWebAppSlot -ResourceGroupName $WEResourceGroupName -Name $WEAppName -AppSettings $WEAppSettings
}

Write-WELog " `nApp Service $WEAppName provisioned successfully" " INFO"
Write-WELog " URL: https://$($WEWebApp.DefaultHostName)" " INFO"
Write-WELog " State: $($WEWebApp.State)" " INFO"

Write-WELog " `nApp Service provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
