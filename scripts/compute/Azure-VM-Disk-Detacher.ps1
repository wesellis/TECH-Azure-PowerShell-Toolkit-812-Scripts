#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Detach VM disks

.DESCRIPTION
    Detach VM disks


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding(SupportsShouldProcess)]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName,
    [Parameter(Mandatory)]
    [string]$DiskName
)
Write-Output "Detaching disk from VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
$DiskToDetach = $VM.StorageProfile.DataDisks | Where-Object { $_.Name -eq $DiskName }
if (-not $DiskToDetach) {
    Write-Error "Disk '$DiskName' not found on VM '$VmName'"
    return
}
Write-Output "Found disk: $DiskName (LUN: $($DiskToDetach.Lun))"
if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Output "Disk detached successfully:"
Write-Output "Disk: $DiskName"
Write-Output "VM: $VmName"
Write-Output "LUN: $($DiskToDetach.Lun)"
Write-Output "Note: Disk is now available for attachment to other VMs"



