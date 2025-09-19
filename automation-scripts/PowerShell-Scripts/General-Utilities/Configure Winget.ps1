#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Configure Winget

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
    We Enhanced Configure Winget

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

Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) 'customization-utils.psm1')

try {
   ;  $pwsh7Exe = " $($env:ProgramFiles)\PowerShell\7\pwsh.exe"
    & $pwsh7Exe -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -File (Join-Path $WEPSScriptRoot 'configure-winget-pwsh7.ps1')
}
catch {
    LogWithTimestamp " !!! [WARN] Unhandled exception (will be ignored):`n$_`n$($_.ScriptStackTrace)"
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
