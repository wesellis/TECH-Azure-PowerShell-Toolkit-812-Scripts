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
    [string]$VmName
)

#region Functions

# Get VM status and details
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status

Write-Information "VM Name: $($VM.Name)"
Write-Information "Resource Group: $($VM.ResourceGroupName)"
Write-Information "Location: $($VM.Location)"
Write-Information "Power State: $($VM.PowerState)"
Write-Information "Provisioning State: $($VM.ProvisioningState)"

# Display status information
foreach ($Status in $VM.Statuses) {
    Write-Information "Status: $($Status.Code) - $($Status.DisplayStatus)"
}


#endregion
