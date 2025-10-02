#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$NetworkWatcherName = "NetworkWatcher_$Location"
)
Write-Output "Enabling Network Watcher in: $Location"
$NetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $ResourceGroupName -Name $NetworkWatcherName -ErrorAction SilentlyContinue
if (-not $NetworkWatcher) {
    $params = @{
        ErrorAction = "Stop"
        ResourceGroupName = $ResourceGroupName
        Name = $NetworkWatcherName
        Location = $Location  Write-Host "Network Watcher created successfully:
    }
    $NetworkWatcher @params
} else {
    Write-Output "Network Watcher already exists:"
}
Write-Output "Name: $($NetworkWatcher.Name)"
Write-Output "Location: $($NetworkWatcher.Location)"
Write-Output "Provisioning State: $($NetworkWatcher.ProvisioningState)"
Write-Output "`nNetwork Watcher capabilities:"
Write-Output "   IP Flow Verify"
Write-Output "   Next Hop"
Write-Output "   Security Group View"
Write-Output "   VPN Diagnostics"
Write-Output "   NSG Flow Logs"
Write-Output "   Connection Monitor"
Write-Output "   Packet Capture"
Write-Output "   Connection Troubleshoot"



