# ============================================================================
# Script Name: Azure VM Disk Detacher
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Safely detaches data disks from Azure Virtual Machines
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName,
    
    [Parameter(Mandatory=$true)]
    [string]$DiskName
)

Write-Information "Detaching disk from VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Find the disk to detach
$DiskToDetach = $VM.StorageProfile.DataDisks | Where-Object { $_.Name -eq $DiskName }

if (-not $DiskToDetach) {
    Write-Error "Disk '$DiskName' not found on VM '$VmName'"
    return
}

Write-Information "Found disk: $DiskName (LUN: $($DiskToDetach.Lun))"

# Remove the disk
Remove-AzVMDataDisk -VM $VM -Name $DiskName

# Update the VM
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM

Write-Information "✅ Disk detached successfully:"
Write-Information "  Disk: $DiskName"
Write-Information "  VM: $VmName"
Write-Information "  LUN: $($DiskToDetach.Lun)"
Write-Information "  Note: Disk is now available for attachment to other VMs"
