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
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName
)

#region Functions

Write-Information "Checking power state for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status
Write-Information "VM: $($VM.Name)"
Write-Information "Power State: $($VM.PowerState)"
Write-Information "Status: $($VM.Statuses | Where-Object { $_.Code -like 'PowerState*' } | Select-Object -ExpandProperty DisplayStatus)"


#endregion
