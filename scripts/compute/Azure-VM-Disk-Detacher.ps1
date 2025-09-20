#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Detach VM disks

.DESCRIPTION
    Detach VM disks


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName,
    [Parameter(Mandatory)]
    [string]$DiskName
)
Write-Host "Detaching disk from VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
# Find the disk to detach
$DiskToDetach = $VM.StorageProfile.DataDisks | Where-Object { $_.Name -eq $DiskName }
if (-not $DiskToDetach) {
    Write-Error "Disk '$DiskName' not found on VM '$VmName'"
    return
}
Write-Host "Found disk: $DiskName (LUN: $($DiskToDetach.Lun))"
# Remove the disk
if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
# Update the VM
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Host "Disk detached successfully:"
Write-Host "Disk: $DiskName"
Write-Host "VM: $VmName"
Write-Host "LUN: $($DiskToDetach.Lun)"
Write-Host "Note: Disk is now available for attachment to other VMs"


