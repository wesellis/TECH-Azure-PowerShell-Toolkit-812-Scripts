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
    [string]$VmName
)

#region Functions

Write-Information "Retrieving disk information for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

Write-Information "`nOS Disk:"
Write-Information "  Name: $($VM.StorageProfile.OsDisk.Name)"
Write-Information "  Size: $($VM.StorageProfile.OsDisk.DiskSizeGB) GB"
Write-Information "  Type: $($VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType)"

if ($VM.StorageProfile.DataDisks.Count -gt 0) {
    Write-Information "`nData Disks:"
    foreach ($Disk in $VM.StorageProfile.DataDisks) {
        Write-Information "  Name: $($Disk.Name) | Size: $($Disk.DiskSizeGB) GB | LUN: $($Disk.Lun)"
    }
} else {
    Write-Information "`nNo data disks attached."
}


#endregion
