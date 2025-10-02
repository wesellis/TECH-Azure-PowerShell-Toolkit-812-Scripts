#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName,
    [Parameter()]
    [string]$StorageAccountName
)
Write-Output "Enabling boot diagnostics for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
if ($StorageAccountName) {
    Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
    Write-Output "Using storage account: $StorageAccountName"
} else {
    Set-AzVMBootDiagnostic -VM $VM -Enable
    Write-Output "Using managed storage"
}
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Output "Boot diagnostics enabled successfully:"
Write-Output "VM: $VmName"
Write-Output "Resource Group: $ResourceGroupName"
if ($StorageAccountName) {
    Write-Output "Storage Account: $StorageAccountName"
}
Write-Output "Status: Enabled"



