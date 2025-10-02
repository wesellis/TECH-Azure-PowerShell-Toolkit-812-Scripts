#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.RecoveryServices

<#`n.SYNOPSIS
    Backup VM disks

.DESCRIPTION
    Backup VM disks


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName
)
Backup-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName




