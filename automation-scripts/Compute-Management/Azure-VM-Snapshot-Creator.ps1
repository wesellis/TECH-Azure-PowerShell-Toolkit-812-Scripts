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
    [string]$ResourceGroupName,
    [string]$SnapshotName,
    [string]$DiskName,
    [string]$Location
)

#region Functions

New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -SourceUri (Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName).Id -Location $Location


#endregion
