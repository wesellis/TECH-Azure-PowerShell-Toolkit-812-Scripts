#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Check VM health

.DESCRIPTION
    Check VM health


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$VmName
)
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status
Write-Output "VM Name: $($VM.Name)"
Write-Output "Resource Group: $($VM.ResourceGroupName)"
Write-Output "Location: $($VM.Location)"
Write-Output "Power State: $($VM.PowerState)"
Write-Output "Provisioning State: $($VM.ProvisioningState)"
foreach ($Status in $VM.Statuses) {
    Write-Output "Status: $($Status.Code) - $($Status.DisplayStatus)"`n}
