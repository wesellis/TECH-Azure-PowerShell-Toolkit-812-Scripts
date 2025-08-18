<#
.SYNOPSIS
    Windows Msbuild Env Invokecommand

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
    We Enhanced Windows Msbuild Env Invokecommand

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
    Sets up a temporary environment for headless Nuget packages restoration and runs requested script in the environment.
.PARAMETER RepoRoot
    Full path to the repo's root directory.
.PARAMETER Script
    Passed to 'cmd.exe /c' for execution after the environment for restoring packages is configured.


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $WERepoRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $WEScript
)

try {
   ;  $WEErrorActionPreference = " Stop"
    Set-StrictMode -Version Latest

    # Detect location of msbuild.exe and add it to the path so it can be referenced from the script by just the file name
    Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-msbuild-utils.psm1')
   ;  $msbuildExeFileDir = Split-Path -Parent (Get-LatestMsbuildLocation)
    $env:PATH += " ;$($msbuildExeFileDir);"

    Set-Location $WERepoRoot

    Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-build-environment-utils.psm1')
    SetPackagesRestoreEnvironmentAndRunScript -RepoRoot $WERepoRoot -RepoKind MSBuild -Script $WEScript
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================