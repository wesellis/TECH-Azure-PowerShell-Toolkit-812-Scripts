<#
.SYNOPSIS
    Windows Vscodeinstall

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
    We Enhanced Windows Vscodeinstall

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [bool] $WEInstallInsiders = $false
)

$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest

function WE-Install-VSCode {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if ($WEInstallInsiders) {
        $WEVSCodeURL = 'https://update.code.visualstudio.com/latest/win32-x64/insider'
    }
    else {
        $WEVSCodeURL = 'https://update.code.visualstudio.com/latest/win32-x64/stable'
    }

    Write-WELog " Downloading from $WEVSCodeURL" " INFO"
    $WEVScodeInstaller = Join-Path $env:TEMP 'VSCodeSetup-x64.exe'
    Invoke-WebRequest -Uri $WEVSCodeURL -UseBasicParsing -OutFile $WEVScodeInstaller

    Write-WELog " Installing VS Code" " INFO"
    $arguments = @('/VERYSILENT', '/NORESTART', '/MERGETASKS=!runcode')
   ;  $installerExitCode = (Start-Process -FilePath $WEVScodeInstaller -ArgumentList $arguments -Wait -Verbose -Passthru).ExitCode
    if ($installerExitCode -ne 0) {
        throw " Failed with exit code $installerExitCode"
    }

   ;  $shortCutPath = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk'
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

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================