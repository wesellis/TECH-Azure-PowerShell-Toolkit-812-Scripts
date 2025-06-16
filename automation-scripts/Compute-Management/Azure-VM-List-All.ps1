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
    Write-Host -Object "Connected to subscription: $SubscriptionId"
}

Write-Host -Object "Retrieving all VMs across subscription..."

$VMs = Get-AzVM -Status
Write-Host -Object "`nFound $($VMs.Count) Virtual Machines:"
Write-Host -Object ("=" * 60)

foreach ($VM in $VMs) {
    Write-Host -Object "VM: $($VM.Name) | RG: $($VM.ResourceGroupName) | State: $($VM.PowerState) | Size: $($VM.HardwareProfile.VmSize)"
}
