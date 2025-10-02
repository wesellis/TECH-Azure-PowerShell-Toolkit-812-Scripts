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
    [string]$ShareName,
    [Parameter()]
    [int]$QuotaInGB = 1024
)
Write-Output "Creating File Share: $ShareName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$params = @{
    ErrorAction = "Stop"
    Context = $Context
    QuotaGiB = $QuotaInGB
    Name = $ShareName
}
$FileShare @params
Write-Output "File Share created successfully:"
Write-Output "Name: $($FileShare.Name)"
Write-Output "Quota: $QuotaInGB GB"
Write-Output "Storage Account: $StorageAccountName"
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Key = $Keys[0].Value
Write-Output "`nConnection Information:"
Write-Output "UNC Path: \\$StorageAccountName.file.core.windows.net\$ShareName"
Write-Output "Mount Command (Windows):"
Write-Output "    net use Z: \\$StorageAccountName.file.core.windows.net\$ShareName /u:AZURE\$StorageAccountName $Key"
Write-Output "Mount Command (Linux):"
Write-Output "    sudo mount -t cifs //$StorageAccountName.file.core.windows.net/$ShareName /mnt/myfileshare -o vers=3.0,username=$StorageAccountName,password=$Key,dir_mode=0777,file_mode=0777"



