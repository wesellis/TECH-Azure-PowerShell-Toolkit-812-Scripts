#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Setup User Tasks

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
    We Enhanced Setup User Tasks

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
    Configures a set of tasks to execute when a user logs into a VM.


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

try {
   ;  $setupScriptsDir = $WEPSScriptRoot

    Write-WELog " === Register the command to run when user logs in for the very first time" " INFO"
   ;  $runKey = " HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    reg.exe add $runKey /f /v " DevBoxImageTemplates" /t " REG_EXPAND_SZ" /d " powershell.exe -ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Minimized $setupScriptsDir\runonce-user-tasks.ps1"
    reg.exe query $runKey /s
}
catch {
    Write-WELog " [WARN] Unhandled exception:" " INFO"
    Write-Information -Object $_
    Write-Information -Object $_.ScriptStackTrace
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
