#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Manage containers

.DESCRIPTION
    Manage containers
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$StorageAccountName,
    [Parameter(Mandatory)]
    [string]$ContainerName,
    [Parameter()]
    [string]$PublicAccess = "Off"
)
Write-Host "Creating storage container: $ContainerName"
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context
$Container = New-AzStorageContainer -Name $ContainerName -Context $Context -Permission $PublicAccess
Write-Host "Container created successfully:"
Write-Host "Name: $($Container.Name)"
Write-Host "Public Access: $PublicAccess"
Write-Host "Storage Account: $StorageAccountName"
Write-Host "URL: $($Container.CloudBlobContainer.StorageUri.PrimaryUri)"

