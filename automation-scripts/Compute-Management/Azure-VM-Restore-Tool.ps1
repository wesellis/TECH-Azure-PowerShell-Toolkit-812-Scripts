<#
.SYNOPSIS
    Restore VM from backup

.DESCRIPTION
    Restore VM from backup
#>
param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName,
    [string]$RestorePoint
)
Restore-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName -RestorePoint $RestorePoint

