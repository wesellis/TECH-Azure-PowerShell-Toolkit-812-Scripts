# ============================================================================
# Script Name: Azure File Share Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure File Shares for SMB/NFS file storage
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ShareName,
    
    [Parameter(Mandatory=$false)]
    [int]$QuotaInGB = 1024
)

Write-Host "Creating File Share: $ShareName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$FileShare = New-AzStorageShare `
    -Name $ShareName `
    -Context $Context `
    -QuotaGiB $QuotaInGB

Write-Host "✅ File Share created successfully:"
Write-Host "  Name: $($FileShare.Name)"
Write-Host "  Quota: $QuotaInGB GB"
Write-Host "  Storage Account: $StorageAccountName"

# Get connection info
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Key = $Keys[0].Value

Write-Host "`nConnection Information:"
Write-Host "  UNC Path: \\$StorageAccountName.file.core.windows.net\$ShareName"
Write-Host "  Mount Command (Windows):"
Write-Host "    net use Z: \\$StorageAccountName.file.core.windows.net\$ShareName /u:AZURE\$StorageAccountName $Key"
Write-Host "  Mount Command (Linux):"
Write-Host "    sudo mount -t cifs //$StorageAccountName.file.core.windows.net/$ShareName /mnt/myfileshare -o vers=3.0,username=$StorageAccountName,password=$Key,dir_mode=0777,file_mode=0777"
