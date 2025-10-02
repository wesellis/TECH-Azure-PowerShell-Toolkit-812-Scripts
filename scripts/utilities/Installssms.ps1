#Requires -Version 7.4

<#
.SYNOPSIS
    Install SQL Server Management Studio

.DESCRIPTION
    Downloads and installs SQL Server Management Studio (SSMS) using Chocolatey package manager.
    Ensures TLS 1.2 is enabled for secure downloads.

.PARAMETER SkipChocoInstall
    Skip Chocolatey installation if already installed

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions and internet connectivity
#>

[CmdletBinding()]
param(
    [switch]$SkipChocoInstall
)

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Starting SQL Server Management Studio installation..."

    # Ensure TLS 1.2 is enabled for secure downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Install Chocolatey if not already installed and not skipped
    if (-not $SkipChocoInstall) {
        Write-Output "Checking for Chocolatey installation..."
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Output "Installing Chocolatey package manager..."
            $currentPolicy = Get-ExecutionPolicy
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }
            finally {
                Set-ExecutionPolicy $currentPolicy -Scope Process -Force
            }
            Write-Output "Chocolatey installed successfully"
        }
        else {
            Write-Output "Chocolatey already installed"
        }
    }
    else {
        Write-Output "Skipping Chocolatey installation as requested"
    }

    # Verify Chocolatey is available
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        throw "Chocolatey is not available. Please install Chocolatey first or run without -SkipChocoInstall"
    }

    # Install SQL Server Management Studio
    Write-Output "Installing SQL Server Management Studio..."
    $chocoProcess = Start-Process -FilePath "choco" -ArgumentList @("install", "sql-server-management-studio", "-y") -Wait -PassThru -NoNewWindow

    if ($chocoProcess.ExitCode -eq 0) {
        Write-Output "SQL Server Management Studio installed successfully"
    }
    else {
        throw "SQL Server Management Studio installation failed with exit code: $($chocoProcess.ExitCode)"
    }

    # Verify installation
    $ssmsPath = "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 19\Common7\IDE\ssms.exe"
    $ssmsPath18 = "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe"

    if ((Test-Path $ssmsPath) -or (Test-Path $ssmsPath18)) {
        Write-Output "SQL Server Management Studio installation verified"
        if (Test-Path $ssmsPath) {
            Write-Output "SSMS 19 installed at: $ssmsPath"
        }
        if (Test-Path $ssmsPath18) {
            Write-Output "SSMS 18 installed at: $ssmsPath18"
        }
    }
    else {
        Write-Warning "SQL Server Management Studio executable not found in expected locations"
    }

    Write-Output "SSMS installation completed successfully"
}
catch {
    $errorMsg = "SSMS installation failed: $($_.Exception.Message)"
    Write-Error $errorMsg
    throw
}