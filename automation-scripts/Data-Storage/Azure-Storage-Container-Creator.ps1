# ============================================================================
# Script Name: Azure Storage Container Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates a new blob container in Azure Storage Account
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$false)]
    [string]$PublicAccess = "Off"
)

Write-Host "Creating storage container: $ContainerName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$Container = New-AzStorageContainer -Name $ContainerName -Context $Context -Permission $PublicAccess

Write-Host "Container created successfully:"
Write-Host "  Name: $($Container.Name)"
Write-Host "  Public Access: $PublicAccess"
Write-Host "  Storage Account: $StorageAccountName"
Write-Host "  URL: $($Container.CloudBlobContainer.StorageUri.PrimaryUri)"
