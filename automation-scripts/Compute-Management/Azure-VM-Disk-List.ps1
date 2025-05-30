# ============================================================================
# Script Name: Azure VM Disk List Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Lists all disks attached to a specific Virtual Machine
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName
)

Write-Host "Retrieving disk information for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

Write-Host "`nOS Disk:"
Write-Host "  Name: $($VM.StorageProfile.OsDisk.Name)"
Write-Host "  Size: $($VM.StorageProfile.OsDisk.DiskSizeGB) GB"
Write-Host "  Type: $($VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType)"

if ($VM.StorageProfile.DataDisks.Count -gt 0) {
    Write-Host "`nData Disks:"
    foreach ($Disk in $VM.StorageProfile.DataDisks) {
        Write-Host "  Name: $($Disk.Name) | Size: $($Disk.DiskSizeGB) GB | LUN: $($Disk.Lun)"
    }
} else {
    Write-Host "`nNo data disks attached."
}
