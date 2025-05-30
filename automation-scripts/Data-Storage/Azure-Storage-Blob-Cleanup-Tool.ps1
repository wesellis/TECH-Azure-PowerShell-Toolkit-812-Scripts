# ============================================================================
# Script Name: Azure Storage Blob Container Cleanup Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates cleanup and removal of Azure Storage Blob containers
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$ContainerName
)

Remove-AzStorageBlob -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $ContainerName -Force
