#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Custom Build Env Invokecommand

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
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
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $Script,
    [Parameter(Mandatory = $false)][String] $RepoPackagesFeed,
    [Parameter(Mandatory = $false)] [string] $AdditionalRepoFeeds
)
try {
    Set-StrictMode -Version Latest
    Set-Location -ErrorAction Stop $RepoRoot
    Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-build-environment-utils.psm1')
    $params = @{
        Script = $Script
        RepoKind = "Custom"
        RepoPackagesFeed = $RepoPackagesFeed
        RepoRoot = $RepoRoot
        AdditionalRepoFeeds = $AdditionalRepoFeeds
    }
    SetPackagesRestoreEnvironmentAndRunScript @params
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
