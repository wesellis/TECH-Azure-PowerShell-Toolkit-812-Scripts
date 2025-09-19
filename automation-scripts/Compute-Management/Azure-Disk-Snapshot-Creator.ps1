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
    [string]$DiskName,
    
    [Parameter(Mandatory=$false)]
    [string]$SnapshotName = "$DiskName-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

#region Functions

Write-Information "Creating snapshot of disk: $DiskName"

$Disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName

$SnapshotConfig = New-AzSnapshotConfig -SourceUri $Disk.Id -Location $Disk.Location -CreateOption Copy

$Snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -Snapshot $SnapshotConfig

Write-Information "Snapshot created successfully:"
Write-Information "  Name: $($Snapshot.Name)"
Write-Information "  Size: $($Snapshot.DiskSizeGB) GB"
Write-Information "  Location: $($Snapshot.Location)"


#endregion
