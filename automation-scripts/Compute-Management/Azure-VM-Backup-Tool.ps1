#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Backup VM disks

.DESCRIPTION
    Backup VM disks\n    Author: Wes Ellis (wes@wesellis.com)\n#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName
)
Backup-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName\n

