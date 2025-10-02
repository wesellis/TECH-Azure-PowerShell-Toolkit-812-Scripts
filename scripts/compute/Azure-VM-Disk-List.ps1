#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    List VM disks

.DESCRIPTION
    List VM disks


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Output "Retrieving disk information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Output "`nOS Disk:"
Write-Output "Name: $($VM.StorageProfile.OsDisk.Name)"
Write-Output "Size: $($VM.StorageProfile.OsDisk.DiskSizeGB) GB"
Write-Output "Type: $($VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType)"
if ($VM.StorageProfile.DataDisks.Count -gt 0) {
    Write-Output "`nData Disks:"
    foreach ($Disk in $VM.StorageProfile.DataDisks) {
        Write-Output "Name: $($Disk.Name) | Size: $($Disk.DiskSizeGB) GB | LUN: $($Disk.Lun)"
    }
} else {
    Write-Output "`nNo data disks attached."`n}
