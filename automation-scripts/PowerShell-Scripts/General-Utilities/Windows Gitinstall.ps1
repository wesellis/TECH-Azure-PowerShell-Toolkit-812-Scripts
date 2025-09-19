#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Gitinstall

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Windows Gitinstall

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    $WESetCredHelper = $false
)

#region Functions
$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest
$WEVerbosePreference = 'Continue'

function getSimpleValue([string] $url, [string] $filename ) {
    $fullpath = " ${env:Temp}\$filename"
    Invoke-WebRequest -Uri $url -OutFile $fullpath
    $value = Get-Content -ErrorAction Stop $fullpath -Raw

    return $value
}


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; 
$gitTag = getSimpleValue -url " https://gitforwindows.org/latest-tag.txt" -filename " gitlatesttag.txt" ; 
$gitVersion = getSimpleValue -url " https://gitforwindows.org/latest-version.txt" -filename " gitlatestversion.txt" ;

$installerFile = " Git-$gitVersion-64-bit.exe" ;

$uri = " https://github.com/git-for-windows/git/releases/download/$gitTag/$installerFile"
$WEInstaller = " $env:Temp\GitInstaller.exe"
$WEProgressPreference = 'SilentlyContinue'
try {
    Invoke-RestMethod -Uri $uri -OutFile $WEInstaller -UseBasicParsing

    # Regarding setting the Components:
    # Download installer from https://git-scm.com/downloads 
    # Run it manually using Git-<version>-64-bit.exe /SAVEINF=" C:\.tools\gitinstall.ini"
    # Select needed components in the UI and complete the install.
    # Use value of 'Components' in generated gitinstall.ini.
    # Reference https://jrsoftware.org/ishelp/index.php?topic=setupcmdline

    $arguments = @('/silent', '/norestart', '/Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh,scalar')

    Write-WELog " Installing $installerFile" " INFO"
    Start-Process -FilePath $WEInstaller -ArgumentList $arguments -Wait -Verbose
    Write-WELog " Done Installing $installerFile" " INFO"

    if ($WESetCredHelper -eq $true) {
        Write-WELog " Setting system git config credential.helper to manager" " INFO"
        $basePath = " C:\Program Files\Git"
        $binPath = Join-Path $basePath " bin\git.exe"
        $cmdPath = Join-Path $basePath " cmd\git.exe"
        if (Test-Path $binPath) {
            $gitPath = $binPath
        }
        else {
           ;  $gitPath = $cmdPath
        }
        if (-not (Test-Path $gitPath)) {
            throw " Unable to find git.exe"
        }
       ;  $arguments = @('config', '--system', 'credential.helper', 'manager')
        Write-WELog " Running $gitPath $($arguments -join ' ')" " INFO"
        & $gitPath $arguments
        Write-Information " Result: $WELastExitCode"
        Write-WELog " Git system config settings:" " INFO"
        & $gitPath @('config', '--system', '--list')
        Write-WELog " Done updating git config" " INFO"
    }
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
