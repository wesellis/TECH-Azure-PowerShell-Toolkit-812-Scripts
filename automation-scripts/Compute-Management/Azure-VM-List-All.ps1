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
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

#region Functions

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
    Write-Information -Object "Connected to subscription: $SubscriptionId"
}

Write-Information -Object "Retrieving all VMs across subscription..."

$VMs = Get-AzVM -Status
Write-Information -Object "`nFound $($VMs.Count) Virtual Machines:"
Write-Information -Object ("=" * 60)

foreach ($VM in $VMs) {
    Write-Information -Object "VM: $($VM.Name) | RG: $($VM.ResourceGroupName) | State: $($VM.PowerState) | Size: $($VM.HardwareProfile.VmSize)"
}


#endregion
