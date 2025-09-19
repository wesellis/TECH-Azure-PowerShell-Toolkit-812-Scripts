#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
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

#region Functions

if (-not $BlobName) {
    $BlobName = Split-Path $LocalFilePath -Leaf
}

Write-Information "Uploading file to blob storage:"
Write-Information "  Local file: $LocalFilePath"
Write-Information "  Blob name: $BlobName"

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

Write-Information " File uploaded successfully!"
Write-Information "  URL: $($Blob.ICloudBlob.StorageUri.PrimaryUri)"


#endregion
