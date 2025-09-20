#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Update VMs

.DESCRIPTION
    Update VMs\n    Author: Wes Ellis (wes@wesellis.com)\n#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [string]$VmName
)
# Add your VM update logic here
# Example: Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Host "Update VM functionality to be implemented for $VmName in $ResourceGroupName"\n

