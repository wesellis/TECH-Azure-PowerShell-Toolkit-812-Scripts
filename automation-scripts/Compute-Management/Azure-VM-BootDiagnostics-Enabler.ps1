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

Write-Host "Enabling boot diagnostics for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

if ($StorageAccountName) {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $StorageUri = $StorageAccount.PrimaryEndpoints.Blob
    
    Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
    Write-Host "Using storage account: $StorageAccountName"
} else {
    Set-AzVMBootDiagnostic -VM $VM -Enable
    Write-Host "Using managed storage"
}

Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM

Write-Host "✅ Boot diagnostics enabled successfully:"
Write-Host "  VM: $VmName"
Write-Host "  Resource Group: $ResourceGroupName"
if ($StorageAccountName) {
    Write-Host "  Storage Account: $StorageAccountName"
}
Write-Host "  Status: Enabled"
