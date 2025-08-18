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

Write-Information "Creating storage container: $ContainerName"

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$Context = $StorageAccount.Context

$Container = New-AzStorageContainer -Name $ContainerName -Context $Context -Permission $PublicAccess

Write-Information "Container created successfully:"
Write-Information "  Name: $($Container.Name)"
Write-Information "  Public Access: $PublicAccess"
Write-Information "  Storage Account: $StorageAccountName"
Write-Information "  URL: $($Container.CloudBlobContainer.StorageUri.PrimaryUri)"
