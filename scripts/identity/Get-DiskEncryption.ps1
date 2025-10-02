#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Check disk encryption status

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
Check encryption status for VMs and disks
.PARAMETER ResourceGroup
Resource group to check
.PARAMETER Unencrypted
Show only unencrypted resources
.\Get-DiskEncryption.ps1
.\Get-DiskEncryption.ps1 -ResourceGroup rg-prod -Unencrypted
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroup,
    [switch]$Unencrypted
)
$vms = if ($ResourceGroup) { Get-AzVM -ResourceGroupName $ResourceGroup } else { Get-AzVM }
$results = foreach ($vm in $vms) {
    $status = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Name = $vm.Name
        ResourceGroup = $vm.ResourceGroupName
        OSEncrypted = $status.OsVolumeEncrypted
        DataEncrypted = $status.DataVolumesEncrypted
    }
}
$disks = if ($ResourceGroup) { Get-AzDisk -ResourceGroupName $ResourceGroup } else { Get-AzDisk }
$results += foreach ($disk in $disks) {
    $encrypted = $disk.Encryption.Type -ne "EncryptionAtRestWithPlatformKey"
    [PSCustomObject]@{
        Name = $disk.Name
        ResourceGroup = $disk.ResourceGroupName
        OSEncrypted = $encrypted
        DataEncrypted = "N/A"
    }
}
if ($Unencrypted) {
    $results | Where-Object { $_.OSEncrypted -ne "Encrypted" -and $_.OSEncrypted -ne $true }
} else {
    $results`n}
