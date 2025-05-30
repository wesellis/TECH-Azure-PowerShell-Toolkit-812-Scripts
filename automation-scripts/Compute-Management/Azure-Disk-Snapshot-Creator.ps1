# ============================================================================
# Script Name: Azure Disk Snapshot Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates a snapshot of an Azure managed disk
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$DiskName,
    
    [Parameter(Mandatory=$false)]
    [string]$SnapshotName = "$DiskName-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

Write-Host "Creating snapshot of disk: $DiskName"

$Disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName

$SnapshotConfig = New-AzSnapshotConfig -SourceUri $Disk.Id -Location $Disk.Location -CreateOption Copy

$Snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -Snapshot $SnapshotConfig

Write-Host "Snapshot created successfully:"
Write-Host "  Name: $($Snapshot.Name)"
Write-Host "  Size: $($Snapshot.DiskSizeGB) GB"
Write-Host "  Location: $($Snapshot.Location)"
