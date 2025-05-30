# ============================================================================
# Script Name: Azure Virtual Machine Health and Status Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Virtual Machine health, status, and performance metrics
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VmName
)

# Get VM status and details
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status

Write-Host "VM Name: $($VM.Name)"
Write-Host "Resource Group: $($VM.ResourceGroupName)"
Write-Host "Location: $($VM.Location)"
Write-Host "Power State: $($VM.PowerState)"
Write-Host "Provisioning State: $($VM.ProvisioningState)"

# Display status information
foreach ($Status in $VM.Statuses) {
    Write-Host "Status: $($Status.Code) - $($Status.DisplayStatus)"
}
