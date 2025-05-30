# ============================================================================
# Script Name: Azure VM Power State Checker
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Quickly checks the power state of an Azure Virtual Machine
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName
)

Write-Host "Checking power state for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status
Write-Host "VM: $($VM.Name)"
Write-Host "Power State: $($VM.PowerState)"
Write-Host "Status: $($VM.Statuses | Where-Object { $_.Code -like 'PowerState*' } | Select-Object -ExpandProperty DisplayStatus)"
