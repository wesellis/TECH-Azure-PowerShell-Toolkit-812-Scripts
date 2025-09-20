<#
.SYNOPSIS
    Backup VM disks

.DESCRIPTION
    Backup VM disks
#>
param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName
)
Backup-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName

