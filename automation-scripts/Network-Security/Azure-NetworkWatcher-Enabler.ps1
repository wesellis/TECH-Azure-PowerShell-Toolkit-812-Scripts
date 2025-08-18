# ============================================================================
# Script Name: Azure Network Watcher Enabler
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Enables Azure Network Watcher for network monitoring and diagnostics
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$NetworkWatcherName = "NetworkWatcher_$Location"
)

Write-Information "Enabling Network Watcher in: $Location"

# Check if Network Watcher already exists
$NetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $ResourceGroupName -Name $NetworkWatcherName -ErrorAction SilentlyContinue

if (-not $NetworkWatcher) {
    # Create Network Watcher
    $NetworkWatcher = New-AzNetworkWatcher -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $NetworkWatcherName `
        -Location $Location
    
    Write-Information "✅ Network Watcher created successfully:"
} else {
    Write-Information "✅ Network Watcher already exists:"
}

Write-Information "  Name: $($NetworkWatcher.Name)"
Write-Information "  Location: $($NetworkWatcher.Location)"
Write-Information "  Provisioning State: $($NetworkWatcher.ProvisioningState)"

Write-Information "`nNetwork Watcher capabilities:"
Write-Information "  • IP Flow Verify"
Write-Information "  • Next Hop"
Write-Information "  • Security Group View"
Write-Information "  • VPN Diagnostics"
Write-Information "  • NSG Flow Logs"
Write-Information "  • Connection Monitor"
Write-Information "  • Packet Capture"
Write-Information "  • Connection Troubleshoot"
