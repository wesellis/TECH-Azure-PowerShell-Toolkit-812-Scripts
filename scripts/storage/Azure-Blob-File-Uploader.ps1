#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
Write-Output "Uploading file to blob storage:"
Write-Output "Local file: $LocalFilePath"
Write-Output "Blob name: $BlobName"
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
Write-Output "File uploaded successfully!"
Write-Output "URL: $($Blob.ICloudBlob.StorageUri.PrimaryUri)"



