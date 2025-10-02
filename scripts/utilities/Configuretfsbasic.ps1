#Requires -Version 7.4

<#
.SYNOPSIS
    Configure TFS Basic

.DESCRIPTION
    Azure automation script for Team Foundation Server basic configuration

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$TfsDownloadUrl = 'https://go.microsoft.com/fwlink/?LinkId=857132'
$InstallDirectory = "${env:ProgramFiles}\Microsoft Team Foundation Server 15.0"
$InstallKey = 'HKLM:\SOFTWARE\Microsoft\DevDiv\tfs\Servicing\15.0\serverCore'

function Ensure-TfsInstalled {
    $TfsInstalled = $false

    if (Test-Path $InstallKey) {
        $key = Get-Item -ErrorAction Stop $InstallKey
        $value = $key.GetValue("Install", $null)
        if (($null -ne $value) -and $value -eq 1) {
            $TfsInstalled = $true
        }
    }

    if (-not $TfsInstalled) {
        Write-Verbose "Installing TFS using ISO"
        $parent = [System.IO.Path]::GetTempPath()
        [string]$name = [System.Guid]::NewGuid()
        [string]$FullPath = Join-Path $parent $name

        try {
            New-Item -ItemType Directory -Path $FullPath | Out-Null

            Write-Verbose "Downloading TFS installer..."
            Invoke-WebRequest -UseBasicParsing -Uri $TfsDownloadUrl -OutFile "$FullPath\tfsserver2017.3.1_enu.iso"

            Write-Verbose "Mounting ISO..."
            $MountResult = Mount-DiskImage "$FullPath\tfsserver2017.3.1_enu.iso" -PassThru
            $DriveLetter = ($MountResult | Get-Volume).DriveLetter

            Write-Verbose "Running TFS installer..."
            $process = Start-Process -FilePath "${DriveLetter}:\TfsServer2017.3.1.exe" -ArgumentList '/quiet' -PassThru -Wait
            $process.WaitForExit()

            Start-Sleep -Seconds 90

            Write-Verbose "Dismounting ISO..."
            Dismount-DiskImage "$FullPath\tfsserver2017.3.1_enu.iso"
        }
        finally {
            if (Test-Path $FullPath) {
                Remove-Item -Path $FullPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        Write-Verbose "TFS is already installed"
    }
}

function Configure-TfsBasic {
    param(
        [string]$SqlInstance = ".\SQLEXPRESS",
        [string]$WebSiteVDir = "DefaultCollection"
    )

    $ConfigPath = "${InstallDirectory}\Tools"
    $TfsConfigExe = Join-Path $ConfigPath "TfsConfig.exe"

    if (-not (Test-Path $TfsConfigExe)) {
        throw "TFS configuration tool not found at: $TfsConfigExe"
    }

    Write-Verbose "Configuring TFS Basic..."

    $arguments = @(
        "unattend"
        "/configure"
        "/type:Basic"
        "/inputs:SqlInstance=$SqlInstance"
        "/inputs:WebSiteVDir=$WebSiteVDir"
    )

    $process = Start-Process -FilePath $TfsConfigExe -ArgumentList $arguments -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "TFS configuration failed with exit code: $($process.ExitCode)"
    }

    Write-Verbose "TFS Basic configuration completed successfully"
}

try {
    Write-Verbose "Starting TFS Basic configuration..."

    # Ensure TFS is installed
    Ensure-TfsInstalled

    # Configure TFS in basic mode
    Configure-TfsBasic

    Write-Verbose "TFS Basic setup completed successfully"
}
catch {
    Write-Error "TFS configuration failed: $($_.Exception.Message)"
    throw
}