#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create VM snapshots

.DESCRIPTION
    Create VM snapshots\n    Author: Wes Ellis (wes@wesellis.com)\n#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$SnapshotName,
    [string]$DiskName,
    [string]$Location
)
New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -SourceUri (Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName).Id -Location $Location\n

