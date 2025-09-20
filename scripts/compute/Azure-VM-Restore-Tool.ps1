#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.RecoveryServices

<#`n.SYNOPSIS
    Restore VM from backup

.DESCRIPTION
    Restore VM from backup


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName,
    [string]$RestorePoint
)
Restore-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName -RestorePoint $RestorePoint


