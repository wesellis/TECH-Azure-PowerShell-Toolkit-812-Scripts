#Requires -Version 7.0

<#`n.SYNOPSIS
    Configure Winget Pwsh7

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Ensure that WinGet is installed and ready to use for the current user.
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) 'customization-utils.psm1')
$isFailed = $false
try {
    LogWithTimestamp " === Ensure WinGet is ready for the current user"
    Repair-WinGetPackageManager -Latest -Force
}
catch {
    LogWithTimestamp " !!! [WARN] Unhandled exception:`n$_`n$($_.ScriptStackTrace)"
$isFailed = $true
}
if ($isFailed) {
    Get-InstalledModule -ErrorAction Stop Microsoft.WinGet.Client | Format-List
    LogWithTimestamp " === Attempt to repair WinGet Client module"
    Uninstall-Module Microsoft.WinGet.Client -AllowPrerelease -AllVersions -Force -ErrorAction Continue
    Install-Module Microsoft.WinGet.Client -Scope AllUsers -Force -ErrorAction Continue
    Repair-WinGetPackageManager -Latest -Force
}
