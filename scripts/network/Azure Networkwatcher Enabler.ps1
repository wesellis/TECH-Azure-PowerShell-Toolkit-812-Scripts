#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Networkwatcher Enabler

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [string]$NetworkWatcherName = "NetworkWatcher_$Location"
)
Write-Output "Enabling Network Watcher in: $Location"
    [string]$NetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $ResourceGroupName -Name $NetworkWatcherName -ErrorAction SilentlyContinue
if (-not $NetworkWatcher) {
    $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $NetworkWatcherName
       Location = $Location  Write-Output "Network Watcher created successfully:" " INFO
   }
   ; @params
} else {
    Write-Output "Network Watcher already exists:"
}
Write-Output "Name: $($NetworkWatcher.Name)"
Write-Output "Location: $($NetworkWatcher.Location)"
Write-Output "Provisioning State: $($NetworkWatcher.ProvisioningState)"
Write-Output " `nNetwork Watcher capabilities:"
Write-Output "   IP Flow Verify"
Write-Output "   Next Hop"
Write-Output "   Security Group View"
Write-Output "   VPN Diagnostics"
Write-Output "   NSG Flow Logs"
Write-Output "   Connection Monitor"
Write-Output "   Packet Capture"
Write-Output "   Connection Troubleshoot"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
