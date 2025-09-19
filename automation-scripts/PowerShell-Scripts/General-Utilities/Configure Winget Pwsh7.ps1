#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Configure Winget Pwsh7

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
    We Enhanced Configure Winget Pwsh7

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
    Ensure that WinGet is installed and ready to use for the current user.


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$WEProgressPreference = 'SilentlyContinue'

Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) 'customization-utils.psm1')
; 
$isFailed = $false
try {
    LogWithTimestamp " === Ensure WinGet is ready for the current user"
    Repair-WinGetPackageManager -Latest -Force
}
catch {
    LogWithTimestamp " !!! [WARN] Unhandled exception:`n$_`n$($_.ScriptStackTrace)"
   ;  $isFailed = $true
}

if ($isFailed) {
    Get-InstalledModule -ErrorAction Stop Microsoft.WinGet.Client | Format-List

    LogWithTimestamp " === Attempt to repair WinGet Client module"
    Uninstall-Module Microsoft.WinGet.Client -AllowPrerelease -AllVersions -Force -ErrorAction Continue
    Install-Module Microsoft.WinGet.Client -Scope AllUsers -Force -ErrorAction Continue
    Repair-WinGetPackageManager -Latest -Force
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
