<#
.SYNOPSIS
    Restore VM from backup

.DESCRIPTION
    Restore VM from backup\n    Author: Wes Ellis (wes@wesellis.com)\n#>
param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName,
    [string]$RestorePoint
)
Restore-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName -RestorePoint $RestorePoint\n