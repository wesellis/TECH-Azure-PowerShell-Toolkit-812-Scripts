<#
.SYNOPSIS
    Upload Storagefile

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$storageContext = @{
    Context   = New-AzStorageContext -StorageAccountName $env:storageAccountName -UseConnectedAccount
    Container = $env:containerName
}
$files = $env:files | ConvertFrom-Json -Depth 10
Write-Output "Uploading ${$files.PSObject.Properties.Count} files..."
$files.PSObject.Properties | ForEach-Object {
$filePath = $_.Name
$tempPath = " ./$($filePath -replace " /" , " _" )"
    Write-Output "  Uploading $filePath..."
    $_.Value | Out-File $tempPath
    Set-AzStorageBlobContent -ErrorAction Stop @storageContext -File $tempPath -Blob $filePath -Force | Out-Null
}\n