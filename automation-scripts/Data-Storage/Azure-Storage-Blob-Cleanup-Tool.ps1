<#
.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$ContainerName
)
Remove-AzStorageBlob -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $ContainerName -Force

