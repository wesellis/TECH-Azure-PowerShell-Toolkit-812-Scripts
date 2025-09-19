#Requires -Version 7.0
#Requires -Module Az.Resources

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
    [string]$NewVmSize
)

#region Functions

# Get current VM
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Update VM size
$VM.HardwareProfile.VmSize = $NewVmSize

# Apply the changes
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM

Write-Information "VM $VmName has been scaled to size: $NewVmSize"


#endregion
