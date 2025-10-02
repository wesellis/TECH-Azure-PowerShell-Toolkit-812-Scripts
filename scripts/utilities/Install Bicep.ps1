#Requires -Version 7.4

<#
.SYNOPSIS
    Install Bicep CLI

.DESCRIPTION
    Azure automation script that installs the Bicep CLI tool for Azure Resource Manager template authoring

.PARAMETER TtkFolder
    The folder path where Bicep will be installed. Defaults to environment variable TTK_FOLDER

.PARAMETER BicepUri
    The URI to download Bicep from. Defaults to environment variable BICEP_URI

.EXAMPLE
    .\Install Bicep.ps1 -TtkFolder "C:\Tools" -BicepUri "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe"
    Installs Bicep CLI to the specified folder

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Internet access to download Bicep
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TtkFolder = $ENV:TTK_FOLDER,

    [Parameter(Mandatory = $false)]
    [string]$BicepUri = $ENV:BICEP_URI
)

$ErrorActionPreference = "Stop"

try {
    # Set default values if not provided
    if ([string]::IsNullOrEmpty($TtkFolder)) {
        $TtkFolder = "$env:LOCALAPPDATA\Programs"
    }

    if ([string]::IsNullOrEmpty($BicepUri)) {
        $BicepUri = "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe"
    }

    Write-Output "Installing Bicep CLI..."
    $InstallPath = "$TtkFolder\bicep"
    $BicepFolder = New-Item -ItemType Directory -Path $InstallPath -Force
    $BicepPath = "$BicepFolder\bicep.exe"

    Write-Output "Downloading Bicep from: $BicepUri"
    Write-Output "Installing to: $BicepPath"

    (New-Object System.Net.WebClient).DownloadFile($BicepUri, $BicepPath)

    if (!(Test-Path $BicepPath)) {
        Write-Error "Couldn't find downloaded file $BicepPath"
    }

    # Add to PATH
    $BicepDirectory = Split-Path $BicepPath
    Write-Output "Adding to PATH: $BicepDirectory"

    # Add to current session PATH
    $ENV:PATH = "$BicepDirectory;$($ENV:PATH)"
    Write-Output "Updated PATH: $ENV:PATH"

    # Verify installation
    $InstalledBicepPath = (Get-Command bicep.exe -ErrorAction SilentlyContinue).Source
    if ($InstalledBicepPath) {
        Write-Output "Using Bicep at: $InstalledBicepPath"

        # Get version information
        $VersionOutput = & bicep --version
        Write-Output "Bicep version: $VersionOutput"

        # Extract version number
        if ($VersionOutput -match "(?<version>[0-9]+\.[-0-9a-z.]+)") {
            $BicepVersion = $matches.version
            Write-Output "Bicep version number: $BicepVersion"
        }

        Write-Output "Bicep CLI installation completed successfully."
    }
    else {
        Write-Error "Bicep installation verification failed. Command not found in PATH."
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}