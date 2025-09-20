<#
.SYNOPSIS
    Azure Appservice Provisioning Tool

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
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PlanName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$Runtime = "DOTNET" ,
    [string]$RuntimeVersion = " 6.0" ,
    [bool]$HttpsOnly = $true,
    [hashtable]$AppSettings = @{}
)
Write-Host "Provisioning App Service: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "App Service Plan: $PlanName"
Write-Host "Location: $Location"
Write-Host "Runtime: $Runtime $RuntimeVersion"
Write-Host "HTTPS Only: $HttpsOnly"
$params = @{
    ErrorAction = "Stop"
    Location = $Location
    ResourceGroupName = $ResourceGroupName
    Name = $AppName
    AppServicePlan = $PlanName
}
$WebApp @params
Write-Host "App Service created: $($WebApp.DefaultHostName)"
if ($Runtime -eq "DOTNET" ) {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -NetFrameworkVersion " v$RuntimeVersion"
}
if ($HttpsOnly) {
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -HttpsOnly $true
    Write-Host "HTTPS-only enforcement enabled"
}
if ($AppSettings.Count -gt 0) {
    Write-Host " `nConfiguring App Settings:"
    foreach ($Setting in $AppSettings.GetEnumerator()) {
        Write-Host "  $($Setting.Key): $($Setting.Value)"
    }
    Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -AppSettings $AppSettings
}
Write-Host " `nApp Service $AppName provisioned successfully"
Write-Host "URL: https://$($WebApp.DefaultHostName)"
Write-Host "State: $($WebApp.State)"
Write-Host " `nApp Service provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n