# ============================================================================
# Script Name: Azure VM List All Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Lists all Virtual Machines across all resource groups with status
# ============================================================================

param (
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
    Write-Host "Connected to subscription: $SubscriptionId"
}

Write-Host "Retrieving all VMs across subscription..."

$VMs = Get-AzVM -Status
Write-Host "`nFound $($VMs.Count) Virtual Machines:"
Write-Host "=" * 60

foreach ($VM in $VMs) {
    Write-Host "VM: $($VM.Name) | RG: $($VM.ResourceGroupName) | State: $($VM.PowerState) | Size: $($VM.HardwareProfile.VmSize)"
}
