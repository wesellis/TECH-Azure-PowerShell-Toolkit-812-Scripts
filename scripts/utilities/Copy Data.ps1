#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Storage

<#
.SYNOPSIS
    Copy Data

.DESCRIPTION
    Azure automation script to download data from a web URI and upload it to Azure Storage.
    This script downloads a CSV file from a web endpoint and uploads it to an Azure Storage container.

.PARAMETER ContentUri
    URI of the content to download (can be provided via environment variable contentUri)

.PARAMETER CsvFileName
    Name of the CSV file to save (can be provided via environment variable csvFileName)

.PARAMETER StorageAccountName
    Name of the Azure Storage Account (can be provided via environment variable storageAccountName)

.PARAMETER StorageAccountKey
    Access key for the Azure Storage Account (can be provided via environment variable storageAccountKey)

.PARAMETER ContainerName
    Name of the storage container to upload to (can be provided via environment variable containerName)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ContentUri = $env:contentUri,

    [Parameter(Mandatory=$false)]
    [string]$CsvFileName = $env:csvFileName,

    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = $env:storageAccountName,

    [Parameter(Mandatory=$false)]
    [string]$StorageAccountKey = $env:storageAccountKey,

    [Parameter(Mandatory=$false)]
    [string]$ContainerName = $env:containerName
)

$ErrorActionPreference = "Stop"

try {
    # Validate required parameters
    if ([string]::IsNullOrWhiteSpace($ContentUri)) {
        Write-Error "ContentUri is required. Please provide it via parameter or contentUri environment variable."
        throw
    }

    if ([string]::IsNullOrWhiteSpace($CsvFileName)) {
        Write-Error "CsvFileName is required. Please provide it via parameter or csvFileName environment variable."
        throw
    }

    if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
        Write-Error "StorageAccountName is required. Please provide it via parameter or storageAccountName environment variable."
        throw
    }

    if ([string]::IsNullOrWhiteSpace($StorageAccountKey)) {
        Write-Error "StorageAccountKey is required. Please provide it via parameter or storageAccountKey environment variable."
        throw
    }

    if ([string]::IsNullOrWhiteSpace($ContainerName)) {
        Write-Error "ContainerName is required. Please provide it via parameter or containerName environment variable."
        throw
    }

    Write-Output "Starting data copy operation..."
    Write-Output "Content URI: $ContentUri"
    Write-Output "CSV File Name: $CsvFileName"
    Write-Output "Storage Account: $StorageAccountName"
    Write-Output "Container Name: $ContainerName"

    # Download the file
    Write-Output "Downloading file from: $ContentUri"
    Invoke-WebRequest -Uri $ContentUri -OutFile $CsvFileName -ErrorAction Stop
    Write-Output "File downloaded successfully: $CsvFileName"

    # Create storage context
    $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

    # Create container if it doesn't exist
    Write-Output "Creating storage container: $ContainerName"
    try {
        New-AzStorageContainer -Context $StorageContext -Name $ContainerName -Permission Off -Verbose
        Write-Output "Container created successfully"
    }
    catch {
        if ($_.Exception.Message -like "*already exists*") {
            Write-Output "Container already exists, continuing..."
        }
        else {
            throw
        }
    }

    # Upload file to storage
    Write-Output "Uploading file to Azure Storage..."
    $UploadParams = @{
        File = $CsvFileName
        Context = $StorageContext
        Blob = $CsvFileName
        Container = $ContainerName
        StandardBlobTier = "Hot"
        Force = $true
    }
    Set-AzStorageBlobContent @UploadParams
    Write-Output "File uploaded successfully to container: $ContainerName"

    # Clean up local file
    if (Test-Path $CsvFileName) {
        Remove-Item $CsvFileName -Force
        Write-Output "Local file cleaned up: $CsvFileName"
    }

    Write-Output "Data copy operation completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"

    # Clean up local file on error
    if (Test-Path $CsvFileName) {
        try {
            Remove-Item $CsvFileName -Force -ErrorAction SilentlyContinue
            Write-Output "Local file cleaned up after error: $CsvFileName"
        }
        catch {
            Write-Warning "Could not clean up local file: $CsvFileName"
        }
    }

    throw
}