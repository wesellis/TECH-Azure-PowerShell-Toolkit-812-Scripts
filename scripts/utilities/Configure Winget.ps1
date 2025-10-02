#Requires -Version 7.4

<#
.SYNOPSIS
    Configure WinGet

.DESCRIPTION
    Azure automation script to ensure that WinGet is installed and ready to use for the current user

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Verbose "[$Timestamp] [$Level] $Message"
}

function Install-WinGet {
    Write-Log "Checking if WinGet is installed..."

    try {
        $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetPath) {
            Write-Log "WinGet is already installed at: $($wingetPath.Source)"
            return $true
        }
    }
    catch {
        Write-Log "WinGet not found, proceeding with installation..." "WARN"
    }

    Write-Log "Installing WinGet and dependencies..."

    try {
        # Install VCLibs dependency
        $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vcLibsPath = Join-Path $env:TEMP "Microsoft.VCLibs.x64.14.00.Desktop.appx"

        Write-Log "Downloading VCLibs..."
        Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsPath -UseBasicParsing

        Write-Log "Installing VCLibs..."
        Add-AppxPackage -Path $vcLibsPath

        # Install UI.Xaml dependency
        $xamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx"
        $xamlPath = Join-Path $env:TEMP "Microsoft.UI.Xaml.2.7.x64.appx"

        Write-Log "Downloading UI.Xaml..."
        Invoke-WebRequest -Uri $xamlUrl -OutFile $xamlPath -UseBasicParsing

        Write-Log "Installing UI.Xaml..."
        Add-AppxPackage -Path $xamlPath

        # Get latest WinGet release from GitHub
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $wingetAsset = $latestRelease.assets | Where-Object { $_.name -match "msixbundle" }

        if (-not $wingetAsset) {
            throw "Could not find WinGet msixbundle in latest release"
        }

        $wingetUrl = $wingetAsset.browser_download_url
        $wingetPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"

        Write-Log "Downloading WinGet from: $wingetUrl"
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath -UseBasicParsing

        Write-Log "Installing WinGet..."
        Add-AppxPackage -Path $wingetPath

        Write-Log "WinGet installation completed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install WinGet: $($_.Exception.Message)"
        throw
    }
    finally {
        # Cleanup temporary files
        @($vcLibsPath, $xamlPath, $wingetPath) | ForEach-Object {
            if ($_ -and (Test-Path $_)) {
                Remove-Item $_ -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Configure-WinGet {
    Write-Log "Configuring WinGet settings..."

    try {
        # Ensure WinGet is in PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        # Accept source agreements
        Write-Log "Accepting WinGet source agreements..."
        winget source update --accept-source-agreements | Out-Null

        # Update sources
        Write-Log "Updating WinGet sources..."
        winget source update | Out-Null

        Write-Log "WinGet configuration completed"
    }
    catch {
        Write-Error "Failed to configure WinGet: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Log "Starting WinGet configuration..."

    # Install WinGet if needed
    if (Install-WinGet) {
        # Configure WinGet
        Configure-WinGet

        Write-Log "WinGet setup completed successfully"
    }
}
catch {
    Write-Error "WinGet configuration failed: $($_.Exception.Message)"
    throw
}