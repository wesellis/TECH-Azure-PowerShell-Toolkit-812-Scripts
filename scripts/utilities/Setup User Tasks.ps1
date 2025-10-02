#Requires -Version 7.4

<#`n.SYNOPSIS
    Setup User Tasks

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Configures a set of tasks to execute when a user logs into a VM.
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
try {
$SetupScriptsDir = $PSScriptRoot
    Write-Output " === Register the command to run when user logs in for the very first time"
$RunKey = "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    reg.exe add $RunKey /f /v "DevBoxImageTemplates"/t "REG_EXPAND_SZ"/d " powershell.exe -ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Minimized $SetupScriptsDir\runonce-user-tasks.ps1"
    reg.exe query $RunKey /s
}
catch {
    Write-Output "[WARN] Unhandled exception:"
    Write-Information -Object $_
    Write-Information -Object $_.ScriptStackTrace`n}
