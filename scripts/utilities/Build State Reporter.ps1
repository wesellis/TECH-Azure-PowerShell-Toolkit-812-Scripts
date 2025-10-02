#Requires -Version 7.4

<#`n.SYNOPSIS
    Build State Reporter

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Reports information about the current build environment.
    The script is expected to be launched from the same environment from where a build is about to be executed right before its start.
$ErrorActionPreference = "Stop";
$EnvVarExclusionList = @()
Set-StrictMode -Version Latest
try {
$MaxValueLength = 8
    Write-Output " === Current environment variables (redacted):"
    Get-ChildItem -ErrorAction Stop env: | ForEach-Object { " $($_.Name)=$(if ($_.Name -notin $EnvVarExclusionList) { $(if ($_.Value.Length -gt $MaxValueLength) { "" $($_.Value.Substring(0,$MaxValueLength))..."" } else { $_.Value }) } else { " <redacted>" })"
} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
