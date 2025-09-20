<#
.SYNOPSIS
    Create VM snapshots

.DESCRIPTION
    Create VM snapshots
#>
param (
    [string]$ResourceGroupName,
    [string]$SnapshotName,
    [string]$DiskName,
    [string]$Location
)
New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -SourceUri (Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName).Id -Location $Location

