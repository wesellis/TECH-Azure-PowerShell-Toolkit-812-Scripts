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
    [string]$ShareName,
    [Parameter()]
    [int]$QuotaInGB = 1024
)
Write-Host "Creating File Share: $ShareName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$params = @{
    ErrorAction = "Stop"
    Context = $Context
    QuotaGiB = $QuotaInGB
    Name = $ShareName
}
$FileShare @params
Write-Host "File Share created successfully:"
Write-Host "Name: $($FileShare.Name)"
Write-Host "Quota: $QuotaInGB GB"
Write-Host "Storage Account: $StorageAccountName"
# Get connection info
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Key = $Keys[0].Value
Write-Host "`nConnection Information:"
Write-Host "UNC Path: \\$StorageAccountName.file.core.windows.net\$ShareName"
Write-Host "Mount Command (Windows):"
Write-Host "    net use Z: \\$StorageAccountName.file.core.windows.net\$ShareName /u:AZURE\$StorageAccountName $Key"
Write-Host "Mount Command (Linux):"
Write-Host "    sudo mount -t cifs //$StorageAccountName.file.core.windows.net/$ShareName /mnt/myfileshare -o vers=3.0,username=$StorageAccountName,password=$Key,dir_mode=0777,file_mode=0777"

