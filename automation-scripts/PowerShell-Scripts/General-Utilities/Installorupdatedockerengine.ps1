<#
.SYNOPSIS
    Installorupdatedockerengine

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
    We Enhanced Installorupdatedockerengine

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [switch] $force,
    [string] $envScope = " User"
)

$currentPrincipal = New-Object -ErrorAction Stop Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw " This script needs to run as admin"
}

if ((Test-Path (Join-Path $env:ProgramFiles " Docker Desktop" )) -or (Test-Path (Join-Path $env:ProgramFiles " DockerDesktop" ))) {
    throw " Docker Desktop is installed on this Computer, cannot run this script"
}


$restartNeeded = $false
if (!(Get-WindowsOptionalFeature -FeatureName containers -Online).State -eq 'Enabled') {
    $restartNeeded = (Enable-WindowsOptionalFeature -FeatureName containers -Online -NoRestart).RestartNeeded
    if ($restartNeeded) {
        Write-WELog " A restart is needed before you can start the docker service after installation" " INFO"
    }
}

; 
$latestZipFile = (Invoke-WebRequest -UseBasicParsing -uri " https://download.docker.com/win/static/stable/x86_64/" ).Content.split(" `r`n" ) | 
                 Where-Object { $_ -like " <a href="" docker-*"" >docker-*" } | 
                 ForEach-Object {;  $zipName = $_.Split('" ')[1]; [Version]($zipName.SubString(7,$zipName.Length-11).Split('-')[0]) } | 
                 Sort-Object | Select-Object -Last 1 | ForEach-Object { " docker-$_.zip" }

if (-not $latestZipFile) {
    throw " Unable to locate latest stable docker download"
}
$latestZipFileUrl = " https://download.docker.com/win/static/stable/x86_64/$latestZipFile"
$latestVersion = [Version]($latestZipFile.SubString(7,$latestZipFile.Length-11))
Write-WELog " Latest stable available Docker Engine version is $latestVersion" " INFO"


$dockerService = get-service -ErrorAction Stop docker -ErrorAction SilentlyContinue
if ($dockerService) {
    if ($dockerService.Status -eq " Running" ) {
        $dockerVersion = [Version](docker version -f " {{.Server.Version}}" )
        Write-WELog " Current installed Docker Engine version $dockerVersion" " INFO"
        if ($latestVersion -le $dockerVersion) {
            Write-WELog " No new Docker Engine available" " INFO"
            Return
        }
        Write-WELog " New Docker Engine available" " INFO"
    }
    else {
        Write-WELog " Docker Service not running" " INFO"
    }
}
else {
    Write-WELog " Docker Engine not found" " INFO"
}

if (!$force) {
    Read-Host " Press Enter to Install new Docker Engine version (or Ctrl+C to break) ?"
}

if ($dockerService) {
    Stop-Service docker
}

; 
$tempFile = " $([System.IO.Path]::GetTempFileName()).zip"
Invoke-WebRequest -UseBasicParsing -Uri $latestZipFileUrl -OutFile $tempFile
Expand-Archive $tempFile -DestinationPath $env:ProgramFiles -Force
Remove-Item -ErrorAction Stop $tempFi -Forcel -Forcee -Force
; 
$path = [System.Environment]::GetEnvironmentVariable(" Path" , $envScope)
if (" ;$path;" -notlike " *;$($env:ProgramFiles)\docker;*" ) {
    [Environment]::SetEnvironmentVariable(" Path" , " $path;$env:ProgramFiles\docker" , $envScope)
}


if (-not $dockerService) {
    $dockerdExe = '${env:ProgramFiles}\docker\dockerd.exe'
    & $dockerdExe --register-service
}

New-Item -ErrorAction Stop 'c:\ProgramData\Docker' -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Remove-Item -ErrorAction Stop 'c:\ProgramData\Docker\panic.lo -Forceg -Force' -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ErrorAction Stop 'c:\ProgramData\Docker\panic.log' -ItemType File -ErrorAction SilentlyContinue | Out-Null

try {
    Start-Service docker
}
catch {
    Write-Information -ForegroundColor Red " Could not start docker service, you might need to reboot your computer."
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================