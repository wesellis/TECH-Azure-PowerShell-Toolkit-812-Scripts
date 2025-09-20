#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [string]$ContainerName,
    [Parameter(Mandatory)]
    [string]$LocalFilePath,
    [Parameter()]
    [string]$BlobName
)
if (-not $BlobName) {
    $BlobName = Split-Path $LocalFilePath -Leaf
}
Write-Host "Uploading file to blob storage:"
Write-Host "Local file: $LocalFilePath"
Write-Host "Blob name: $BlobName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$params = @{
    File = $LocalFilePath
    ErrorAction = "Stop"
    Context = $Context
    Blob = $BlobName
    Container = $ContainerName
}
$Blob @params
Write-Host "File uploaded successfully!"
Write-Host "URL: $($Blob.ICloudBlob.StorageUri.PrimaryUri)"

