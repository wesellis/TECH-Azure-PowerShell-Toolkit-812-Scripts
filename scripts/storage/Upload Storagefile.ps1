#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Upload Storagefile

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$StorageContext = @{
    Context   = New-AzStorageContext -StorageAccountName $env:storageAccountName -UseConnectedAccount
    Container = $env:containerName
}
$files = $env:files | ConvertFrom-Json -Depth 10
Write-Output "Uploading ${$files.PSObject.Properties.Count} files..."
$files.PSObject.Properties | ForEach-Object {
$FilePath = $_.Name
$TempPath = " ./$($FilePath -replace "/" , " _" )"
    Write-Output "  Uploading $FilePath..."
    $_.Value | Out-File $TempPath
    Set-AzStorageBlobContent -ErrorAction Stop @storageContext -File $TempPath -Blob $FilePath -Force | Out-Null`n}
