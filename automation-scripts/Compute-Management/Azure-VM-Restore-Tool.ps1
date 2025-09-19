#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName,
    [string]$RestorePoint
)

#region Functions

Restore-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName -RestorePoint $RestorePoint


#endregion
