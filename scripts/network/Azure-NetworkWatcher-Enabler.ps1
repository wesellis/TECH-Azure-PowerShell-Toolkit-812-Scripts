#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$NetworkWatcherName = "NetworkWatcher_$Location"
)
Write-Host "Enabling Network Watcher in: $Location"
# Check if Network Watcher already exists
$NetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $ResourceGroupName -Name $NetworkWatcherName -ErrorAction SilentlyContinue
if (-not $NetworkWatcher) {
    # Create Network Watcher
    $params = @{
        ErrorAction = "Stop"
        ResourceGroupName = $ResourceGroupName
        Name = $NetworkWatcherName
        Location = $Location  Write-Host "Network Watcher created successfully:
    }
    $NetworkWatcher @params
} else {
    Write-Host "Network Watcher already exists:"
}
Write-Host "Name: $($NetworkWatcher.Name)"
Write-Host "Location: $($NetworkWatcher.Location)"
Write-Host "Provisioning State: $($NetworkWatcher.ProvisioningState)"
Write-Host "`nNetwork Watcher capabilities:"
Write-Host "   IP Flow Verify"
Write-Host "   Next Hop"
Write-Host "   Security Group View"
Write-Host "   VPN Diagnostics"
Write-Host "   NSG Flow Logs"
Write-Host "   Connection Monitor"
Write-Host "   Packet Capture"
Write-Host "   Connection Troubleshoot"

