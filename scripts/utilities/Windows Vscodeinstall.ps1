#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Vscodeinstall

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules

function Write-Host {
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
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
    Write-Output "Downloading from $VSCodeURL"
    $VScodeInstaller = Join-Path $env:TEMP 'VSCodeSetup-x64.exe'
    Invoke-WebRequest -Uri $VSCodeURL -UseBasicParsing -OutFile $VScodeInstaller
    Write-Output "Installing VS Code"
    $arguments = @('/VERYSILENT', '/NORESTART', '/MERGETASKS=!runcode')
    $InstallerExitCode = (Start-Process -FilePath $VScodeInstaller -ArgumentList $arguments -Wait -Verbose -Passthru).ExitCode
    if ($InstallerExitCode -ne 0) {
        throw "Failed with exit code $InstallerExitCode"
    }
    $ShortCutPath = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk'
    if (Test-Path $ShortCutPath) {
        Copy-Item -Path $ShortCutPath -Destination C:\Users\Public\Desktop
    }
}
try {
    Install-VSCode
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
