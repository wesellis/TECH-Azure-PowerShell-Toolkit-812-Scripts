#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Msbuild Env Invokecommand

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Sets up a temporary environment for headless Nuget packages restoration and runs requested script in the environment.
.PARAMETER RepoRoot
    Full path to the repo's root directory.
.PARAMETER Script
    Passed to 'cmd.exe /c' for execution after the environment for restoring packages is configured.
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $Script
)
try {
    Set-StrictMode -Version Latest
    Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-msbuild-utils.psm1')
    $MsbuildExeFileDir = Split-Path -Parent (Get-LatestMsbuildLocation)
    $env:PATH += " ;$($MsbuildExeFileDir);"
    Set-Location -ErrorAction Stop $RepoRoot
    Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-build-environment-utils.psm1')
    SetPackagesRestoreEnvironmentAndRunScript -RepoRoot $RepoRoot -RepoKind MSBuild -Script $Script
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
