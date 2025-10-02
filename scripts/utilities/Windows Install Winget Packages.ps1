#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Install Winget Packages

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Installs a set of WinGet packages. Relies on windows-install-winget being executed prior to this script.
.PARAMETER Packages
    Packages to install in the format 'package-id-1[@version-1],package-id-2[@version-2],...'.
.PARAMETER IgnorePackageInstallFailures
    Allows ignoring failures while installing individual packages and let image creation to continue to be able to inspect logs.
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
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $Packages,
    [Parameter(Mandatory = $false)] [bool] $IgnorePackageInstallFailures = $false
)
Set-StrictMode -Version Latest
    $ProgressPreference = 'SilentlyContinue'
function Write-Log {
function Write-Host {
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
    )
    Write-Output " --- Invoking $CommandLine"
    & ([ScriptBlock]::Create($CommandLine))
}
function Install-WinGet-Packages -ErrorAction Stop {
function Write-Host {
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $Packages,
        [Parameter(Mandatory = $false)] [bool] $IgnorePackageInstallFailures
    )
    Write-Output " === Microsoft.DesktopAppInstaller package info: $(Get-AppxPackage -ErrorAction Stop Microsoft.DesktopAppInstaller | Out-String)"
    $WinGetAppInfo = Get-Command -ErrorAction Stop " winget.exe" -ErrorAction SilentlyContinue
    if (!$WinGetAppInfo) {
        throw 'Could not locate winget.exe'
    }
    $WinGetPath = $WinGetAppInfo.Path
    Write-Output " === Found $WinGetPath ; 'winget.exe --info' output: $(Invoke-Executable " $WinGetPath --info" | Out-String)"
    $PackagesArray = @($Packages -Split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    Write-Output " === Installing $($PackagesArray.Count) package(s)"
    $script:successfullyInstalledCount = 0
    foreach ($package in $PackagesArray) {
        Write-Output " === Installing package $package"
    $PackageInfoParts = @($package -Split '@' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    $PackageId = $PackageInfoParts[0]
    $VersionArg = ''
        if ($PackageInfoParts.Count -gt 2) {
            throw "Unexpected format for package $package. Expected format is package-id[@version]"
        }
        elseif ($PackageInfoParts.Count -eq 2) {
    $VersionArg = " --version $($PackageInfoParts[1])"
        }
    $RunBlock = {
    $script:LASTEXITCODE = 0
            Invoke-Executable " $WinGetPath install --id $PackageId $VersionArg --exact --disable-interactivity --silent --no-upgrade --accept-package-agreements --accept-source-agreements --verbose-logs --scope machine --force"
            if ($global:LASTEXITCODE -ne 0) {
                throw "Failed to install $package with exit code $global:LASTEXITCODE. WinGet return codes are listed at https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md"
            }
    $script:successfullyInstalledCount++
        }
        RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 1 -ignoreFailure $IgnorePackageInstallFailures
    }
    Write-Output " === Successfully installed $script:successfullyInstalledCount of $($PackagesArray.Count) package(s)"
    Write-Output " === Granting read and execute permissions to BUILTIN\Users on $env:ProgramFiles\WinGet\Packages"
    Invoke-Executable " $env:SystemRoot\System32\icacls.exe "" $env:ProgramFiles\WinGet\Packages""/t /q /grant ""BUILTIN\Users:(rx)"""
    $WinGetLogsDir = 'C:\.tools\Setup\Logs\WinGet'
    mkdir $WinGetLogsDir -ErrorAction SilentlyContinue | Out-Null
    Invoke-Executable " robocopy.exe /R:5 /W:5 /S $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir $WinGetLogsDir"
    & cmd.exe /c " echo Reset last exit code to 0"
}
if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
                Install-WinGet-Packages -Packages $Packages -IgnorePackageInstallFailures $IgnorePackageInstallFailures
    }
    catch {
        Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
    }
`n}
