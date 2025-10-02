#Requires -Version 7.4

<#
.SYNOPSIS
    Install or Update Docker Engine

.DESCRIPTION
    Downloads and installs the latest stable Docker Engine for Windows Server.
    Checks for existing installations and enables required Windows features.

.PARAMETER Force
    Skip confirmation prompt before installation

.PARAMETER EnvScope
    Environment variable scope for PATH updates (User or Machine)

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions and Windows Server
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [ValidateSet('User', 'Machine')]
    [string]$EnvScope = 'Machine'
)

$ErrorActionPreference = 'Stop'

# Check for admin privileges
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "This script needs to run as administrator"
}

# Check for Docker Desktop installation
if ((Test-Path (Join-Path $env:ProgramFiles "Docker Desktop")) -or (Test-Path (Join-Path $env:ProgramFiles "DockerDesktop"))) {
    throw "Docker Desktop is installed on this computer, cannot run this script"
}

# Enable containers feature if not already enabled
$RestartNeeded = $false
if ((Get-WindowsOptionalFeature -FeatureName containers -Online).State -ne 'Enabled') {
    Write-Verbose "Enabling Windows containers feature"
    $RestartNeeded = (Enable-WindowsOptionalFeature -FeatureName containers -Online -NoRestart).RestartNeeded
    if ($RestartNeeded) {
        Write-Warning "A restart is needed before you can start the docker service after installation"
    }
}

# Get latest Docker Engine version
Write-Verbose "Checking for latest Docker Engine version"
try {
    $webResponse = Invoke-WebRequest -UseBasicParsing -Uri "https://download.docker.com/win/static/stable/x86_64/"
    $LatestZipFile = $webResponse.Content.Split("`r`n") |
        Where-Object { $_ -like "*<a href=`"docker-*`">docker-*" } |
        ForEach-Object {
            $ZipName = $_.Split('"')[1]
            $versionString = $ZipName.Substring(7, $ZipName.Length - 11).Split('-')[0]
            [PSCustomObject]@{
                Version = [Version]$versionString
                FileName = "docker-$versionString.zip"
            }
        } |
        Sort-Object Version |
        Select-Object -Last 1
}
catch {
    throw "Unable to locate latest stable docker download: $($_.Exception.Message)"
}

if (-not $LatestZipFile) {
    throw "Unable to locate latest stable docker download"
}

$LatestZipFileUrl = "https://download.docker.com/win/static/stable/x86_64/$($LatestZipFile.FileName)"
$LatestVersion = $LatestZipFile.Version
Write-Output "Latest stable available Docker Engine version is $LatestVersion"

# Check current Docker installation
$DockerService = Get-Service -Name docker -ErrorAction SilentlyContinue
if ($DockerService) {
    if ($DockerService.Status -eq "Running") {
        try {
            $DockerVersion = [Version](docker version -f "{{.Server.Version}}")
            Write-Output "Current installed Docker Engine version $DockerVersion"
            if ($LatestVersion -le $DockerVersion) {
                Write-Output "No new Docker Engine available"
                return
            }
            Write-Output "New Docker Engine available"
        }
        catch {
            Write-Warning "Could not determine current Docker version"
        }
    }
    else {
        Write-Output "Docker Service not running"
    }
}
else {
    Write-Output "Docker Engine not found"
}

# Confirmation prompt
if (-not $Force) {
    $response = Read-Host "Press Enter to Install new Docker Engine version (or Ctrl+C to break)?"
}

# Stop Docker service if running
if ($DockerService) {
    Write-Verbose "Stopping Docker service"
    Stop-Service docker -Force
}

# Download and install Docker
$TempFile = [System.IO.Path]::GetTempFileName() + ".zip"
try {
    Write-Output "Downloading Docker Engine $LatestVersion..."
    Invoke-WebRequest -UseBasicParsing -Uri $LatestZipFileUrl -OutFile $TempFile

    Write-Output "Installing Docker Engine..."
    Expand-Archive $TempFile -DestinationPath $env:ProgramFiles -Force

    # Update PATH if needed
    $path = [System.Environment]::GetEnvironmentVariable("Path", $EnvScope)
    $dockerPath = "$($env:ProgramFiles)\docker"
    if (";$path;" -notlike "*;$dockerPath;*") {
        Write-Verbose "Adding Docker to PATH"
        [Environment]::SetEnvironmentVariable("Path", "$path;$dockerPath", $EnvScope)
        $env:Path = "$env:Path;$dockerPath"  # Update current session
    }

    # Register Docker service if not already registered
    if (-not $DockerService) {
        Write-Verbose "Registering Docker service"
        $DockerdExe = "${env:ProgramFiles}\docker\dockerd.exe"
        & $DockerdExe --register-service
    }

    # Create Docker data directory and panic log
    $dockerDataPath = 'C:\ProgramData\Docker'
    New-Item -Path $dockerDataPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path "$dockerDataPath\panic.log" -Force -ErrorAction SilentlyContinue
    New-Item -Path "$dockerDataPath\panic.log" -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null

    # Start Docker service
    Write-Output "Starting Docker service..."
    try {
        Start-Service docker
        Write-Output "Docker Engine $LatestVersion installed and started successfully"
    }
    catch {
        Write-Warning "Could not start docker service, you might need to reboot your computer."
        Write-Warning "Error: $($_.Exception.Message)"
    }
}
catch {
    Write-Error "Failed to install Docker Engine: $($_.Exception.Message)"
    throw
}
finally {
    # Clean up temp file
    if (Test-Path $TempFile) {
        Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
    }
}