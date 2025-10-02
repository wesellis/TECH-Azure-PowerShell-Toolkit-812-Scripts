#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Update Settings

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Enable and disable setting in Windows update.
    This script enables the following settings:
        - Notify me when a restart is required to finish updating.
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
try {
    Write-Output "Windows update settings are being configured ..."
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'RestartNotificationsAllowed2' -Value 1
    Write-Output "Windows update settings complete"
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
