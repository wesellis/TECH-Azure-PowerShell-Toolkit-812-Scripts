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
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$NetworkWatcherName = "NetworkWatcher_$Location"
)

#region Functions

Write-Information "Enabling Network Watcher in: $Location"

# Check if Network Watcher already exists
$NetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $ResourceGroupName -Name $NetworkWatcherName -ErrorAction SilentlyContinue

if (-not $NetworkWatcher) {
    # Create Network Watcher
    $params = @{
        ErrorAction = "Stop"
        ResourceGroupName = $ResourceGroupName
        Name = $NetworkWatcherName
        Location = $Location  Write-Information " Network Watcher created successfully:
    }
    $NetworkWatcher @params
} else {
    Write-Information " Network Watcher already exists:"
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


#endregion
