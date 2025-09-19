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
    [string]$VmName,
    [string]$DiskName,
    [int]$NewSizeGB
)

#region Functions

Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName -DiskSizeGB $NewSizeGB


#endregion
