#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Create Devenv Shortcut

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Create a shortcut to a dev repo.
    Add enlistment shortcut to the desktop.
.PARAMETER RepoRoot
    Full path to the repo's root directory.
.PARAMETER RepoKind
    Allowed values are MSBuild, Custom or Data.
.PARAMETER DesktopShortcutScriptPath
    Optional relative batch script path used to create shortcut (no arguments). By default Visual Studio's VsDevCmd.bat is used for MSBuild repos.
.PARAMETER ShortcutRunAsAdmin
    Should the shortcut run as Admin (requests elevation when opened). Default is true
.PARAMETER DesktopShortcutName
    Optional name of the shortcut. By default the name is the repo name.
.PARAMETER DesktopShortcutIconPath
    Optional relative path or full path to the icon file to be used for the shortcut. By default the icon is not set.
.PARAMETER DesktopShortcutHost
    Optional launches shortcut in Windows ConsoleHost or Windows Terminal. Default is Windows Console.
    Sample Bicep snippets for using the artifact:
    {
      name: 'windows-create-devenv-shortcut'
      parameters: {
        RepoRoot: repoRootDir
        RepoKind: 'MSBuild'
      }
    }
    {
      name: 'windows-create-devenv-shortcut'
      parameters: {
        RepoRoot: repoRootDir
        RepoKind: 'Custom'
        DesktopShortcutName: 'DevBuildEnv'
        DesktopShortcutScriptPath: 'tools\\devBuildEnv.cmd'
        DesktopShortcutIconPath: 'tools\\devBuildEnv.ico'
        DesktopShortcutHost: 'Terminal'
      }
    }
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoKind,
    [Parameter(Mandatory = $false)][String] $DesktopShortcutScriptPath,
    [Parameter(Mandatory = $false)][bool] $ShortcutRunAsAdmin = $false,
    [Parameter(Mandatory = $false)][String] $DesktopShortcutIconPath,
    [Parameter(Mandatory = $false)][String] $DesktopShortcutName,
    [Parameter(Mandatory = $false)][String] $DesktopShortcutHost = "Console"
)
Set-StrictMode -Version Latest
function New-Shortcut($InvokecommandScriptPath, $ShortcutName, $ShortcutTargetPath, $ShortcutArguments, $ShortcutIcon, $ShortcutRunAsAdmin) {
    & $InvokecommandScriptPath -ShortcutName $ShortcutName -ShortcutTargetPath $ShortcutTargetPath -ShortcutArguments $ShortcutArguments -ShortcutIcon $ShortcutIcon -EnableRunAsAdmin $ShortcutRunAsAdmin
}
function RunScriptCreatehortcut($RepoRoot, $RepoKind, $DesktopShortcutScriptPath, $ShortcutRunAsAdmin, $DesktopShortcutIconPath, $DesktopShortcutName, $DesktopShortcutHost) {
    if ([string]::IsNullOrEmpty($DesktopShortcutScriptPath)) {
        if ($RepoKind -eq 'MSBuild') {
            Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-msbuild-utils.psm1')
    $DesktopShortcutScriptPath = $(Get-LatestVisualStudioDeveloperEnvironmentScriptPath)
        }
        elseif ($RepoKind -eq 'Custom') {
            Write-Output "No value provided for DesktopShortcutScriptPath"
        }
        elseif ($RepoKind -eq 'Data') {
            Write-Output "No value provided for DesktopShortcutScriptPath"
        }
        else {
            throw "Unknown repo kind $RepoKind"
        }
    }
    else {
        if (!(($RepoKind -eq 'MSBuild') -or ($RepoKind -eq 'Custom') -or ($RepoKind -eq 'Data'))) {
            throw "Unknown repo kind $RepoKind"
        }
    }
    if (![string]::IsNullOrEmpty($DesktopShortcutScriptPath)) {
        if (!([System.IO.Path]::IsPathRooted($DesktopShortcutScriptPath))) {
    $DesktopShortcutScriptPath = " $RepoRoot\$DesktopShortcutScriptPath"
        }
    }
    Write-Output "Getting ready to create shortcut for $RepoKind repo $RepoRoot with script path $DesktopShortcutScriptPath run as admin $ShortcutRunAsAdmin"
    $ShortcutIcon = '';
    if ($DesktopShortcutIconPath -and ([System.IO.Path]::IsPathRooted($DesktopShortcutIconPath) -eq $false)) {
    $ShortcutIcon = Join-Path -Path $RepoRoot -ChildPath $DesktopShortcutIconPath
    }
    else {
    $ShortcutIcon = $DesktopShortcutIconPath
    }
    [String];  $ShortcutName = '';
    if ($DesktopShortcutName) {
    $ShortcutName = $DesktopShortcutName
    }
    else {
    $ShortcutName = $RepoRoot.Split(" \" ) | Where-Object { $_ -ne '' } | Select-Object -Last 1;
    }
    [String] $ShortcutTargetPath = '';
    [String] $ShortcutArguments = '';
    $IsTerminalHost = ![string]::IsNullOrEmpty($DesktopShortcutHost) -and ($DesktopShortcutHost -eq "Terminal" )
    if ([string]::IsNullOrEmpty($DesktopShortcutScriptPath)) {
    $ShortcutTargetPath = $env:ComSpec
    $ShortcutArguments = "/k cd /d $RepoRoot"
    }
    elseif (($DesktopShortcutScriptPath -Like " *.cmd" ) -or ($DesktopShortcutScriptPath -Like " *.bat" )) {
    $ShortcutTargetPath = $env:ComSpec
        if (!$IsTerminalHost) {
    $ShortcutArguments = "/k cd /d $RepoRoot&"" $DesktopShortcutScriptPath"""
        }
        else {
    $ShortcutArguments = "/k "" cd /d $RepoRoot&"" $DesktopShortcutScriptPath"""""""
        }
    }
    elseif ($DesktopShortcutScriptPath -Like " *.ps1" ) {
    $ShortcutTargetPath = " powershell.exe"
    $ShortcutArguments = " -NoExit -File "" $DesktopShortcutScriptPath"""
    }
    else {
        throw "Unknown enviroment to create desktop shortcut with given script path: $DesktopShortcutScriptPath"
    }
    if ($IsTerminalHost) {
    $ShortcutArguments = $ShortcutTargetPath + " " + $ShortcutArguments
    $ShortcutTargetPath = " %LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe"
    }
    Write-Output "Creating shortcut with Target path: $ShortcutTargetPath and Arguments: $ShortcutArguments "
    $InvokecommandScriptPath = (Join-Path $(Split-Path -Parent $PSScriptRoot) 'windows-create-shortcut/windows-create-shortcut.ps1')
    New-Shortcut -ErrorAction Stop $InvokecommandScriptPath $ShortcutName $ShortcutTargetPath $ShortcutArguments $ShortcutIcon $ShortcutRunAsAdmin
    Write-Output "Sucessfully created shortcut with $InvokecommandScriptPath"
}
if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
    $params = @{
            DesktopShortcutName = $DesktopShortcutName
            DesktopShortcutScriptPath = $DesktopShortcutScriptPath
            RepoKind = $RepoKind
            ErrorAction = "Stop }"
            RepoRoot = $RepoRoot
            ShortcutRunAsAdmin = $ShortcutRunAsAdmin
            DesktopShortcutIconPath = $DesktopShortcutIconPath
        }
        RunScriptCreatehortcut @params`n}
