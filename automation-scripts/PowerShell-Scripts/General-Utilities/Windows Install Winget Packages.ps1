#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Install Winget Packages

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
    We Enhanced Windows Install Winget Packages

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.DESCRIPTION
    Installs a set of WinGet packages. Relies on windows-install-winget being executed prior to this script.
.PARAMETER Packages
    Packages to install in the format 'package-id-1[@version-1],package-id-2[@version-2],...'.
.PARAMETER IgnorePackageInstallFailures
    Allows ignoring failures while installing individual packages and let image creation to continue to be able to inspect logs.
.EXAMPLE
        Sample Bicep snippet for using the artifact:

        // WinGet packages to install for all users during image creation.
        // To discover ids of WinGet packages use 'winget search' command.
        // To check whether a package supports machine-wide install run 'winget show --scope Machine --id <package-id>'
        var winGetPackageIds = [
          'WinDirStat.WinDirStat@1.1.2'
          'Kubernetes.kubectl'
          'Microsoft.Azure.AZCopy.10'
        ]

        var additionalArtifacts = [
        {
            name: 'windows-install-winget-packages'
            parameters: {
            packages: join(winGetPackageIds, ',')
          }
        }


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $WEPackages,
    [Parameter(Mandatory = $false)] [bool] $WEIgnorePackageInstallFailures = $false
)

#region Functions

$WEErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$WEProgressPreference = 'SilentlyContinue'

[CmdletBinding()]
function WE-Invoke-Executable {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $commandLine
    )

    Write-WELog " --- Invoking $commandLine" " INFO"
    & ([ScriptBlock]::Create($commandLine))
}

[CmdletBinding()]
function WE-Install-WinGet-Packages -ErrorAction Stop {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $WEPackages,
        [Parameter(Mandatory = $false)] [bool] $WEIgnorePackageInstallFailures
    )

    Write-WELog " === Microsoft.DesktopAppInstaller package info: $(Get-AppxPackage -ErrorAction Stop Microsoft.DesktopAppInstaller | Out-String)" " INFO"

   ;  $winGetAppInfo = Get-Command -ErrorAction Stop " winget.exe" -ErrorAction SilentlyContinue
    if (!$winGetAppInfo) {
        throw 'Could not locate winget.exe'
    }

   ;  $winGetPath = $winGetAppInfo.Path
    Write-WELog " === Found $winGetPath ; 'winget.exe --info' output: $(Invoke-Executable " " INFO" $winGetPath --info" | Out-String)"

    $packagesArray = @($WEPackages -Split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    Write-WELog " === Installing $($packagesArray.Count) package(s)" " INFO"

    $script:successfullyInstalledCount = 0
    foreach ($package in $packagesArray) {
        Write-WELog " === Installing package $package" " INFO"
        $packageInfoParts = @($package -Split '@' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

        $packageId = $packageInfoParts[0]
        $versionArg = ''
        if ($packageInfoParts.Count -gt 2) {
            throw " Unexpected format for package $package. Expected format is package-id[@version]"
        }
        elseif ($packageInfoParts.Count -eq 2) {
            $versionArg = " --version $($packageInfoParts[1])"
        }

       ;  $runBlock = {
            $script:LASTEXITCODE = 0
            Invoke-Executable " $WEWinGetPath install --id $packageId $versionArg --exact --disable-interactivity --silent --no-upgrade --accept-package-agreements --accept-source-agreements --verbose-logs --scope machine --force"
            if ($global:LASTEXITCODE -ne 0) {
                throw " Failed to install $package with exit code $global:LASTEXITCODE. WinGet return codes are listed at https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md"
            }

            $script:successfullyInstalledCount++
        }

        RunWithRetries -runBlock $runBlock -retryAttempts 5 -waitBeforeRetrySeconds 1 -ignoreFailure $WEIgnorePackageInstallFailures
    }

    Write-WELog " === Successfully installed $script:successfullyInstalledCount of $($packagesArray.Count) package(s)" " INFO"

    Write-WELog " === Granting read and execute permissions to BUILTIN\Users on $env:ProgramFiles\WinGet\Packages" " INFO"
    Invoke-Executable " $env:SystemRoot\System32\icacls.exe "" $env:ProgramFiles\WinGet\Packages"" /t /q /grant "" BUILTIN\Users:(rx)"""

    # Backup latest WinGet logs to allow inspection on a Dev Box VM
   ;  $winGetLogsDir = 'C:\.tools\Setup\Logs\WinGet'
    mkdir $winGetLogsDir -ErrorAction SilentlyContinue | Out-Null
    Invoke-Executable " robocopy.exe /R:5 /W:5 /S $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir $winGetLogsDir"
    & cmd.exe /c " echo Reset last exit code to 0"
}

if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-retry-utils.psm1')
        Install-WinGet-Packages -Packages $WEPackages -IgnorePackageInstallFailures $WEIgnorePackageInstallFailures
    }
    catch {
        Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
