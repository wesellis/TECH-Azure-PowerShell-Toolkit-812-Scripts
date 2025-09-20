<#
.SYNOPSIS
    Backup VM disks

.DESCRIPTION
    Backup VM disks\n    Author: Wes Ellis (wes@wesellis.com)\n#>
param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName
)
Backup-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName\n