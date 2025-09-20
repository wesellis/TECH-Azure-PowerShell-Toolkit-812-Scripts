#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName,
    [Parameter()]
    [string]$StorageAccountName
)
Write-Host "Enabling boot diagnostics for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
if ($StorageAccountName) {
    Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
    Write-Host "Using storage account: $StorageAccountName"
} else {
    Set-AzVMBootDiagnostic -VM $VM -Enable
    Write-Host "Using managed storage"
}
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Host "Boot diagnostics enabled successfully:"
Write-Host "VM: $VmName"
Write-Host "Resource Group: $ResourceGroupName"
if ($StorageAccountName) {
    Write-Host "Storage Account: $StorageAccountName"
}
Write-Host "Status: Enabled"


