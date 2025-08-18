<#
.SYNOPSIS
    Windows Custom Build Env Invokecommand

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
    We Enhanced Windows Custom Build Env Invokecommand

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
    Sets up a temporary environment for headless packages restoration and runs the requested script in the environment.
.PARAMETER RepoRoot
    Full path to the repo's root directory.
.PARAMETER RepoPackagesFeed
    Optional ADO Nuget feed URI (even when the repo doesn't use Nuget and only uses NPM for example). The URI is used when restoring packages for the repo. The feed will typically have multiple upstreams.
.PARAMETER AdditionalRepoFeeds
    Optional comma separated list of Nuget feeds that are used during repo setup/build.
.PARAMETER Script
    Passed to 'cmd.exe /c' for execution after the environment for restoring packages is configured.


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $WERepoRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $WEScript,
    [Parameter(Mandatory = $false)][String] $WERepoPackagesFeed,
    [Parameter(Mandatory = $false)] [string] $WEAdditionalRepoFeeds
)

try {
   ;  $WEErrorActionPreference = " Stop"
    Set-StrictMode -Version Latest

    Set-Location $WERepoRoot
    Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-build-environment-utils.psm1')

    SetPackagesRestoreEnvironmentAndRunScript -RepoRoot $WERepoRoot -RepoKind Custom -Script $WEScript `
        -RepoPackagesFeed $WERepoPackagesFeed -AdditionalRepoFeeds $WEAdditionalRepoFeeds 
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================