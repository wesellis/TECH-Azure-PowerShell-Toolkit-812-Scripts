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

Write-Information "VM Name: $($VM.Name)"
Write-Information "Resource Group: $($VM.ResourceGroupName)"
Write-Information "Location: $($VM.Location)"
Write-Information "Power State: $($VM.PowerState)"
Write-Information "Provisioning State: $($VM.ProvisioningState)"

# Display status information
foreach ($Status in $VM.Statuses) {
    Write-Information "Status: $($Status.Code) - $($Status.DisplayStatus)"
}
