<#
.SYNOPSIS
    Windows Create Devenv Shortcut

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
    We Enhanced Windows Create Devenv Shortcut

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
.SYNOPSIS
    Create a shortcut to a dev repo. 
.DESCRIPTION
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

.EXAMPLE
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
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $WERepoRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $WERepoKind,
    [Parameter(Mandatory = $false)][String] $WEDesktopShortcutScriptPath,
    [Parameter(Mandatory = $false)][bool] $WEShortcutRunAsAdmin = $false,
    [Parameter(Mandatory = $false)][String] $WEDesktopShortcutIconPath,
    [Parameter(Mandatory = $false)][String] $WEDesktopShortcutName,
    [Parameter(Mandatory = $false)][String] $WEDesktopShortcutHost = " Console"
)

$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest


function WE-New-Shortcut($invokecommandScriptPath, $shortcutName, $shortcutTargetPath, $shortcutArguments, $shortcutIcon, $shortcutRunAsAdmin) {
    & $invokecommandScriptPath -ShortcutName $shortcutName -ShortcutTargetPath $shortcutTargetPath -ShortcutArguments $shortcutArguments -ShortcutIcon $shortcutIcon -EnableRunAsAdmin $shortcutRunAsAdmin
}

function WE-RunScriptCreatehortcut($WERepoRoot, $WERepoKind, $WEDesktopShortcutScriptPath, $WEShortcutRunAsAdmin, $WEDesktopShortcutIconPath, $WEDesktopShortcutName, $WEDesktopShortcutHost) {
    # Check RepoKind
    if ([string]::IsNullOrEmpty($WEDesktopShortcutScriptPath)) {
        if ($WERepoKind -eq 'MSBuild') {
            Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-msbuild-utils.psm1')
            $WEDesktopShortcutScriptPath = $(Get-LatestVisualStudioDeveloperEnvironmentScriptPath)
        }
        elseif ($WERepoKind -eq 'Custom') {
            Write-WELog " No value provided for DesktopShortcutScriptPath" " INFO" 
        }
        elseif ($WERepoKind -eq 'Data') {
            Write-WELog " No value provided for DesktopShortcutScriptPath" " INFO"
        }
        else {
            throw " Unknown repo kind $WERepoKind"
        }
    }
    else {
        if (!(($WERepoKind -eq 'MSBuild') -or ($WERepoKind -eq 'Custom') -or ($WERepoKind -eq 'Data'))) {
            throw " Unknown repo kind $WERepoKind"
        }
    }

    if (![string]::IsNullOrEmpty($WEDesktopShortcutScriptPath)) {     
        # If the path is relative then calculate the full path
        if (!([System.IO.Path]::IsPathRooted($WEDesktopShortcutScriptPath))) {
           ;  $WEDesktopShortcutScriptPath = " $WERepoRoot\$WEDesktopShortcutScriptPath"
        }
    }
    
    Write-WELog " Getting ready to create shortcut for $WERepoKind repo $WERepoRoot with script path $WEDesktopShortcutScriptPath run as admin $WEShortcutRunAsAdmin" " INFO"

   ;  $WEShortcutIcon = '';

    # Calculate the full path if the icon path is relative
    if ($WEDesktopShortcutIconPath -and ([System.IO.Path]::IsPathRooted($WEDesktopShortcutIconPath) -eq $false)) {
        $WEShortcutIcon = Join-Path -Path $WERepoRoot -ChildPath $WEDesktopShortcutIconPath
    }
    else {
       ;  $WEShortcutIcon = $WEDesktopShortcutIconPath
    }

    [String];  $WEShortcutName = '';

    if ($WEDesktopShortcutName) {
        $WEShortcutName = $WEDesktopShortcutName
    }
    else {
       ;  $WEShortcutName = $WERepoRoot.Split(" \" ) | Where-Object { $_ -ne '' } | Select-Object -Last 1;
    }

    [String] $shortcutTargetPath = '';
    [String] $shortcutArguments = '';

    # Check script file extension
    $isTerminalHost = ![string]::IsNullOrEmpty($WEDesktopShortcutHost) -and ($WEDesktopShortcutHost -eq " Terminal" )
    if ([string]::IsNullOrEmpty($WEDesktopShortcutScriptPath)) {
        $shortcutTargetPath = $env:ComSpec
        $shortcutArguments = " /k cd /d $WERepoRoot"
    }
    elseif (($WEDesktopShortcutScriptPath -Like " *.cmd" ) -or ($WEDesktopShortcutScriptPath -Like " *.bat" )) {
        $shortcutTargetPath = $env:ComSpec
        if (!$isTerminalHost) {
            $shortcutArguments = " /k cd /d $WERepoRoot&"" $WEDesktopShortcutScriptPath"""
        }
        else {
            # Weird but seems like the only combination of quotes that works whether the path has spaces or not
            $shortcutArguments = " /k "" cd /d $WERepoRoot&"" $WEDesktopShortcutScriptPath"""""""
        }
    }
    elseif ($WEDesktopShortcutScriptPath -Like " *.ps1" ) {
        $shortcutTargetPath = " powershell.exe"
        $shortcutArguments = " -NoExit -File "" $WEDesktopShortcutScriptPath"""
    }
    else {
        throw " Unknown enviroment to create desktop shortcut with given script path: $WEDesktopShortcutScriptPath"
    }
    if ($isTerminalHost) {
        $shortcutArguments = $shortcutTargetPath + " " + $shortcutArguments
       ;  $shortcutTargetPath = " %LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe"
    }

    Write-WELog " Creating shortcut with Target path: $shortcutTargetPath and Arguments: $shortcutArguments " " INFO" 
    
   ;  $invokecommandScriptPath = (Join-Path $(Split-Path -Parent $WEPSScriptRoot) 'windows-create-shortcut/windows-create-shortcut.ps1')
    New-Shortcut $invokecommandScriptPath $WEShortcutName $WEShortcutTargetPath $shortcutArguments $WEShortcutIcon $WEShortcutRunAsAdmin

    Write-WELog " Sucessfully created shortcut with $invokecommandScriptPath" " INFO"
}

if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        RunScriptCreatehortcut -RepoRoot $WERepoRoot `
            -RepoKind $WERepoKind `
            -DesktopShortcutScriptPath $WEDesktopShortcutScriptPath `
            -ShortcutRunAsAdmin $WEShortcutRunAsAdmin `
            -DesktopShortcutIconPath $WEDesktopShortcutIconPath `
            -DesktopShortcutName $WEDesktopShortcutName `
            -DesktopShortcutHost $WEDesktopShortcutHost
    }
    catch {
        Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
    }
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================