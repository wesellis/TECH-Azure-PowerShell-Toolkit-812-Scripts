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
    [string]$ShareName,
    
    [Parameter(Mandatory=$false)]
    [int]$QuotaInGB = 1024
)

#region Functions

Write-Information "Creating File Share: $ShareName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$params = @{
    ErrorAction = "Stop"
    Context = $Context
    QuotaGiB = $QuotaInGB
    Name = $ShareName
}
$FileShare @params

Write-Information " File Share created successfully:"
Write-Information "  Name: $($FileShare.Name)"
Write-Information "  Quota: $QuotaInGB GB"
Write-Information "  Storage Account: $StorageAccountName"

# Get connection info
$Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Key = $Keys[0].Value

Write-Information "`nConnection Information:"
Write-Information "  UNC Path: \\$StorageAccountName.file.core.windows.net\$ShareName"
Write-Information "  Mount Command (Windows):"
Write-Information "    net use Z: \\$StorageAccountName.file.core.windows.net\$ShareName /u:AZURE\$StorageAccountName $Key"
Write-Information "  Mount Command (Linux):"
Write-Information "    sudo mount -t cifs //$StorageAccountName.file.core.windows.net/$ShareName /mnt/myfileshare -o vers=3.0,username=$StorageAccountName,password=$Key,dir_mode=0777,file_mode=0777"


#endregion
