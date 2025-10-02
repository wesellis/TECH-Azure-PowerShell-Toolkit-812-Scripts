#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Enable static website hosting on Azure Storage Account.

.DESCRIPTION
    This script enables static website hosting on an Azure Storage Account and uploads
    default index and error documents. The script reads configuration from environment
    variables for flexibility in different deployment scenarios.

.PARAMETER ResourceGroupName
    The name of the Azure Resource Group containing the Storage Account.

.PARAMETER StorageAccountName
    The name of the Azure Storage Account to enable static website hosting on.

.PARAMETER IndexDocumentPath
    The path/name of the index document (default: index.html).

.PARAMETER ErrorDocument404Path
    The path/name of the 404 error document (default: error.html).

.PARAMETER IndexDocumentContents
    The HTML content for the index document.

.PARAMETER ErrorDocument404Contents
    The HTML content for the 404 error document.

.EXAMPLE
    .\Enable-Static-Website.ps1 -ResourceGroupName "myRG" -StorageAccountName "mystorageaccount"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Requires Az.Resources and Az.Storage modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = $env:ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = $env:StorageAccountName,

    [Parameter(Mandatory = $false)]
    [string]$IndexDocumentPath = $env:IndexDocumentPath ?? "index.html",

    [Parameter(Mandatory = $false)]
    [string]$ErrorDocument404Path = $env:ErrorDocument404Path ?? "error.html",

    [Parameter(Mandatory = $false)]
    [string]$IndexDocumentContents = $env:IndexDocumentContents ?? "<html><head><title>Welcome</title></head><body><h1>Welcome to our website!</h1></body></html>",

    [Parameter(Mandatory = $false)]
    [string]$ErrorDocument404Contents = $env:ErrorDocument404Contents ?? "<html><head><title>Page Not Found</title></head><body><h1>404 - Page Not Found</h1></body></html>"
)

$ErrorActionPreference = 'Stop'

try {
    if (-not $ResourceGroupName) {
        throw "ResourceGroupName is required. Provide it as a parameter or set the ResourceGroupName environment variable."
    }

    if (-not $StorageAccountName) {
        throw "StorageAccountName is required. Provide it as a parameter or set the StorageAccountName environment variable."
    }

    Write-Output "Getting storage account '$StorageAccountName' from resource group '$ResourceGroupName'..."
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName
    $ctx = $StorageAccount.Context

    Write-Output "Enabling static website hosting..."
    Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $IndexDocumentPath -ErrorDocument404Path $ErrorDocument404Path

    Write-Output "Creating and uploading index document..."
    $TempIndexFile = New-TemporaryFile -ErrorAction Stop
    Set-Content $TempIndexFile $IndexDocumentContents -Force
    Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $TempIndexFile -Blob $IndexDocumentPath -Properties @{'ContentType' = 'text/html'} -Force

    Write-Output "Creating and uploading 404 error document..."
    $TempErrorDocument404File = New-TemporaryFile -ErrorAction Stop
    Set-Content $TempErrorDocument404File $ErrorDocument404Contents -Force
    Set-AzStorageBlobContent -Context $ctx -Container '$web' -File $TempErrorDocument404File -Blob $ErrorDocument404Path -Properties @{'ContentType' = 'text/html'} -Force

    # Clean up temporary files
    Remove-Item $TempIndexFile -Force -ErrorAction SilentlyContinue
    Remove-Item $TempErrorDocument404File -Force -ErrorAction SilentlyContinue

    Write-Output "Static website hosting enabled successfully for storage account '$StorageAccountName'."
    Write-Output "Index document: $IndexDocumentPath"
    Write-Output "Error document: $ErrorDocument404Path"
}
catch {
    Write-Error "Failed to enable static website hosting: $($_.Exception.Message)"
    throw
}