<#
.SYNOPSIS
    Add Defender Exclusions

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
    We Enhanced Add Defender Exclusions

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.DESCRIPTION
    Add Windows Defender exclusion that can access user local environment variables.
    Related: https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/configure-extension-file-exclusions-microsoft-defender-antivirus?view=o365-worldwide#system-environment-variables
.EXAMPLE
    Sample Bicep snippet for adding the task via Dev Box Image Templates:

    {
        Task: 'add-defender-exclusions'
        Parameters: {
            DirsToExclude: [
                '%TEMP%\\CloudStore'
                '%TEMP%\\NuGetScratch'
                '%TEMP%\\MSBuildTemp%USERNAME%'
            ]
    }


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][PSObject] $WETaskParams
)
; 
$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest

try {
    foreach ($dir in $WETaskParams.DirsToExclude) {
       ;  $expandedDir = [Environment]::ExpandEnvironmentVariables($dir)
        Add-MpPreference -ExclusionPath $expandedDir
        Write-WELog " Added Windows Defender exlusion for $expandedDir" " INFO"
    }
}
catch {
    Write-WELog " !!! [WARN] Unhandled exception (will be ignored):" " INFO"
    Write-Host -Object $_
    Write-Host -Object $_.ScriptStackTrace
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================