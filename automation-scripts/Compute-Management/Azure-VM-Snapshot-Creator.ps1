# ============================================================================
# Script Name: Azure Virtual Machine Snapshot Creation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates snapshots of Azure VM disks for backup and recovery purposes
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$SnapshotName,
    [string]$DiskName,
    [string]$Location
)

New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -SourceUri (Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName).Id -Location $Location
