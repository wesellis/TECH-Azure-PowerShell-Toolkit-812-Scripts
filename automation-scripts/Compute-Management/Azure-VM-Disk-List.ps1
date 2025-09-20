<#
.SYNOPSIS
    List VM disks

.DESCRIPTION
    List VM disks\n    Author: Wes Ellis (wes@wesellis.com)\n#>
param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Host "Retrieving disk information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Host "`nOS Disk:"
Write-Host "Name: $($VM.StorageProfile.OsDisk.Name)"
Write-Host "Size: $($VM.StorageProfile.OsDisk.DiskSizeGB) GB"
Write-Host "Type: $($VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType)"
if ($VM.StorageProfile.DataDisks.Count -gt 0) {
    Write-Host "`nData Disks:"
    foreach ($Disk in $VM.StorageProfile.DataDisks) {
        Write-Host "Name: $($Disk.Name) | Size: $($Disk.DiskSizeGB) GB | LUN: $($Disk.Lun)"
    }
} else {
    Write-Host "`nNo data disks attached."
}\n