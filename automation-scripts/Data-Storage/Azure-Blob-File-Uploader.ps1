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

Write-Information "Uploading file to blob storage:"
Write-Information "  Local file: $LocalFilePath"
Write-Information "  Blob name: $BlobName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$Blob = Set-AzStorageBlobContent -ErrorAction Stop `
    -File $LocalFilePath `
    -Container $ContainerName `
    -Blob $BlobName `
    -Context $Context

Write-Information "✅ File uploaded successfully!"
Write-Information "  URL: $($Blob.ICloudBlob.StorageUri.PrimaryUri)"
