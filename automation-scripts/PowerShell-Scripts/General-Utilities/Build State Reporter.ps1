#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Build State Reporter

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
    We Enhanced Build State Reporter

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.DESCRIPTION
    Reports information about the current build environment.
    The script is expected to be launched from the same environment from where a build is about to be executed right before its start.


$WEErrorActionPreference = "Stop"; 
$WEEnvVarExclusionList = @()
Set-StrictMode -Version Latest

try {
   ;  $maxValueLength = 8
    Write-WELog " === Current environment variables (redacted):" " INFO"
    # Never print full values because they may contain secrets
    Get-ChildItem -ErrorAction Stop env: | ForEach-Object { " $($_.Name)=$(if ($_.Name -notin $WEEnvVarExclusionList) { $(if ($_.Value.Length -gt $maxValueLength) { "" $($_.Value.Substring(0,$maxValueLength))..."" } else { $_.Value }) } else { " <redacted>" })" }
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
