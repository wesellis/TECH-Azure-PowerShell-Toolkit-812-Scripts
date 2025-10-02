#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Manage containers

.DESCRIPTION
    Manage containers
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [string]$ContainerName,
    [Parameter()]
    [string]$PublicAccess = "Off"
)
Write-Output "Creating storage container: $ContainerName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$Container = New-AzStorageContainer -Name $ContainerName -Context $Context -Permission $PublicAccess
Write-Output "Container created successfully:"
Write-Output "Name: $($Container.Name)"
Write-Output "Public Access: $PublicAccess"
Write-Output "Storage Account: $StorageAccountName"
Write-Output "URL: $($Container.CloudBlobContainer.StorageUri.PrimaryUri)"



