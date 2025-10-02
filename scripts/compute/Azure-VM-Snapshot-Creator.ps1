#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create VM snapshots

.DESCRIPTION
    Create VM snapshots


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$SnapshotName,
    [string]$DiskName,
    [string]$Location
)
New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -SourceUri (Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName).Id -Location $Location



