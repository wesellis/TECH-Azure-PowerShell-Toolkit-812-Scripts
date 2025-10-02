#Requires -Version 7.4

<#
.SYNOPSIS
    Copy File from Azure

.DESCRIPTION
    Azure automation script to download a file from Azure artifacts location and save it locally.
    This script constructs the download URL using artifacts location, SAS token, and file path,
    then downloads the file to a local Windows Azure directory.

.PARAMETER ArtifactsLocation
    Base URL of the Azure artifacts location

.PARAMETER ArtifactsLocationSasToken
    SAS token for accessing the artifacts location

.PARAMETER FolderName
    Name of the folder containing the file to download

.PARAMETER FileToInstall
    Name of the file to download and install

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ArtifactsLocation,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ArtifactsLocationSasToken,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$FolderName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$FileToInstall
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Starting file copy from Azure artifacts..."
    Write-Output "Artifacts Location: $ArtifactsLocation"
    Write-Output "Folder Name: $FolderName"
    Write-Output "File to Install: $FileToInstall"

    # Construct the source URL
    # Remove any trailing slash from ArtifactsLocation
    $ArtifactsLocationClean = $ArtifactsLocation.TrimEnd('/')
    $SourceUrl = "$ArtifactsLocationClean/$FolderName/$FileToInstall$ArtifactsLocationSasToken"

    Write-Output "Source URL: $SourceUrl"

    # Create the destination directory
    $DestinationPath = "C:\WindowsAzure\$FolderName"
    Write-Output "Creating destination directory: $DestinationPath"

    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force
        Write-Output "Directory created successfully"
    }
    else {
        Write-Output "Directory already exists"
    }

    # Download the file
    $DestinationFile = Join-Path $DestinationPath $FileToInstall
    Write-Output "Downloading file to: $DestinationFile"

    Invoke-WebRequest -Uri $SourceUrl -OutFile $DestinationFile -ErrorAction Stop

    # Verify the file was downloaded
    if (Test-Path $DestinationFile) {
        $FileSize = (Get-Item $DestinationFile).Length
        Write-Output "File downloaded successfully. Size: $FileSize bytes"
    }
    else {
        Write-Error "File download failed - destination file not found"
        throw
    }

    Write-Output "File copy from Azure completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}