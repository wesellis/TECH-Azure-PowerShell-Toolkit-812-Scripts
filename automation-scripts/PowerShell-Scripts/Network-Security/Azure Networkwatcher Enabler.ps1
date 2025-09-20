#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Networkwatcher Enabler

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Enabling Network Watcher in: $Location"
$NetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $ResourceGroupName -Name $NetworkWatcherName -ErrorAction SilentlyContinue
if (-not $NetworkWatcher) {
    # Create Network Watcher
   $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $NetworkWatcherName
       Location = $Location  Write-Host "Network Watcher created successfully:" " INFO
   }
   ; @params
} else {
    Write-Host "Network Watcher already exists:"
}
Write-Host "Name: $($NetworkWatcher.Name)"
Write-Host "Location: $($NetworkWatcher.Location)"
Write-Host "Provisioning State: $($NetworkWatcher.ProvisioningState)"
Write-Host " `nNetwork Watcher capabilities:"
Write-Host "   IP Flow Verify"
Write-Host "   Next Hop"
Write-Host "   Security Group View"
Write-Host "   VPN Diagnostics"
Write-Host "   NSG Flow Logs"
Write-Host "   Connection Monitor"
Write-Host "   Packet Capture"
Write-Host "   Connection Troubleshoot"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

