# ============================================================================
# Script Name: Azure Blob File Uploader
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Uploads a local file to Azure Blob Storage
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$true)]
    [string]$LocalFilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$BlobName
)

if (-not $BlobName) {
    $BlobName = Split-Path $LocalFilePath -Leaf
}

Write-Host "Uploading file to blob storage:"
Write-Host "  Local file: $LocalFilePath"
Write-Host "  Blob name: $BlobName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$Blob = Set-AzStorageBlobContent `
    -File $LocalFilePath `
    -Container $ContainerName `
    -Blob $BlobName `
    -Context $Context

Write-Host "✅ File uploaded successfully!"
Write-Host "  URL: $($Blob.ICloudBlob.StorageUri.PrimaryUri)"
