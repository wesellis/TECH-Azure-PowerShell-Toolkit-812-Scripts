<#
.SYNOPSIS
    Upload Storagefile

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Upload Storagefile

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$storageContext = @{
    Context   = New-AzStorageContext -StorageAccountName $env:storageAccountName -UseConnectedAccount
    Container = $env:containerName
}


$files = $env:files | ConvertFrom-Json -Depth 10
Write-Output "Uploading ${$files.PSObject.Properties.Count} files..."
$files.PSObject.Properties | ForEach-Object {
   ;  $filePath = $_.Name
   ;  $tempPath = " ./$($filePath -replace " /" , " _" )"
    Write-Output "  Uploading $filePath..."
    $_.Value | Out-File $tempPath
    Set-AzStorageBlobContent @storageContext -File $tempPath -Blob $filePath -Force | Out-Null
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================