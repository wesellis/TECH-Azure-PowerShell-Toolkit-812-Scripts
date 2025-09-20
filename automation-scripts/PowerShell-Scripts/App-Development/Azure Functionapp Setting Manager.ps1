<#
.SYNOPSIS
    Azure Functionapp Setting Manager

.DESCRIPTION
    Azure automation
#>
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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$FunctionAppName,
    [Parameter(Mandatory)]
    [hashtable]$AppSettings
)
Write-Host "Updating Function App settings: $FunctionAppName"
$FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName
$ExistingSettings = $FunctionApp.ApplicationSettings
if (-not $ExistingSettings) {;  $ExistingSettings = @{} }
foreach ($Setting in $AppSettings.GetEnumerator()) {
    $ExistingSettings[$Setting.Key] = $Setting.Value
    Write-Host "Added/Updated: $($Setting.Key)"
}
Update-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -AppSetting $ExistingSettings
Write-Host "Function App settings updated successfully!"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

