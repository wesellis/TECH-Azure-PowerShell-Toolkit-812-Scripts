#Requires -Version 7.0

<#`n.SYNOPSIS
    Windows Vscodeinstall

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules

[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [bool] $InstallInsiders = $false
)
Set-StrictMode -Version Latest
function Install-VSCode {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if ($InstallInsiders) {
        $VSCodeURL = 'https://update.code.visualstudio.com/latest/win32-x64/insider'
    }
    else {
        $VSCodeURL = 'https://update.code.visualstudio.com/latest/win32-x64/stable'
    }
    Write-Host "Downloading from $VSCodeURL"
    $VScodeInstaller = Join-Path $env:TEMP 'VSCodeSetup-x64.exe'
    Invoke-WebRequest -Uri $VSCodeURL -UseBasicParsing -OutFile $VScodeInstaller
    Write-Host "Installing VS Code"
    $arguments = @('/VERYSILENT', '/NORESTART', '/MERGETASKS=!runcode')
$installerExitCode = (Start-Process -FilePath $VScodeInstaller -ArgumentList $arguments -Wait -Verbose -Passthru).ExitCode
    if ($installerExitCode -ne 0) {
        throw "Failed with exit code $installerExitCode"
    }
$shortCutPath = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk'
    if (Test-Path $shortCutPath) {
        Copy-Item -Path $shortCutPath -Destination C:\Users\Public\Desktop
    }
}
try {
    Install-VSCode
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}
