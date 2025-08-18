# ============================================================================
# Script Name: Azure VM Boot Diagnostics Enabler
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Enables boot diagnostics for Azure Virtual Machines
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName
)

Write-Information "Enabling boot diagnostics for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

if ($StorageAccountName) {
    Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
    Write-Information "Using storage account: $StorageAccountName"
} else {
    Set-AzVMBootDiagnostic -VM $VM -Enable
    Write-Information "Using managed storage"
}

Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM

Write-Information "✅ Boot diagnostics enabled successfully:"
Write-Information "  VM: $VmName"
Write-Information "  Resource Group: $ResourceGroupName"
if ($StorageAccountName) {
    Write-Information "  Storage Account: $StorageAccountName"
}
Write-Information "  Status: Enabled"
