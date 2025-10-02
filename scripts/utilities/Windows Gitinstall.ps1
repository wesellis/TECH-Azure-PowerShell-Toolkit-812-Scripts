#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Gitinstall

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter()]
    $SetCredHelper = $false
)
    $VerbosePreference = 'Continue'
function getSimpleValue([string] $url, [string] $filename ) {
    $fullpath = " ${env:Temp}\$filename"
    Invoke-WebRequest -Uri $url -OutFile $fullpath
    $value = Get-Content -ErrorAction Stop $fullpath -Raw
    return $value
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
    $GitTag = getSimpleValue -url " https://gitforwindows.org/latest-tag.txt" -filename " gitlatesttag.txt" ;
    $GitVersion = getSimpleValue -url " https://gitforwindows.org/latest-version.txt" -filename " gitlatestversion.txt" ;
    $InstallerFile = "Git-$GitVersion-64-bit.exe" ;
    $uri = "https://github.com/git-for-windows/git/releases/download/$GitTag/$InstallerFile"
    $Installer = " $env:Temp\GitInstaller.exe"
    $ProgressPreference = 'SilentlyContinue'
try {
    Invoke-RestMethod -Uri $uri -OutFile $Installer -UseBasicParsing
    $arguments = @('/silent', '/norestart', '/Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh,scalar')
    Write-Output "Installing $InstallerFile"
    Start-Process -FilePath $Installer -ArgumentList $arguments -Wait -Verbose
    Write-Output "Done Installing $InstallerFile"
    if ($SetCredHelper -eq $true) {
        Write-Output "Setting system git config credential.helper to manager"
    $BasePath = "C:\Program Files\Git"
    $BinPath = Join-Path $BasePath " bin\git.exe"
    $CmdPath = Join-Path $BasePath " cmd\git.exe"
        if (Test-Path $BinPath) {
    $GitPath = $BinPath
        }
        else {
    $GitPath = $CmdPath
        }
        if (-not (Test-Path $GitPath)) {
            throw "Unable to find git.exe"
        }
    $arguments = @('config', '--system', 'credential.helper', 'manager')
        Write-Output "Running $GitPath $($arguments -join ' ')"
        & $GitPath $arguments
        Write-Output "Result: $LastExitCode"
        Write-Output "Git system config settings:"
        & $GitPath @('config', '--system', '--list')
        Write-Output "Done updating git config"

} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
