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

Write-Host "Enabling Network Watcher in: $Location"

# Check if Network Watcher already exists
$NetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $ResourceGroupName -Name $NetworkWatcherName -ErrorAction SilentlyContinue

if (-not $NetworkWatcher) {
    # Create Network Watcher
    $NetworkWatcher = New-AzNetworkWatcher `
        -ResourceGroupName $ResourceGroupName `
        -Name $NetworkWatcherName `
        -Location $Location
    
    Write-Host "✅ Network Watcher created successfully:"
} else {
    Write-Host "✅ Network Watcher already exists:"
}

Write-Host "  Name: $($NetworkWatcher.Name)"
Write-Host "  Location: $($NetworkWatcher.Location)"
Write-Host "  Provisioning State: $($NetworkWatcher.ProvisioningState)"

Write-Host "`nNetwork Watcher capabilities:"
Write-Host "  • IP Flow Verify"
Write-Host "  • Next Hop"
Write-Host "  • Security Group View"
Write-Host "  • VPN Diagnostics"
Write-Host "  • NSG Flow Logs"
Write-Host "  • Connection Monitor"
Write-Host "  • Packet Capture"
Write-Host "  • Connection Troubleshoot"
