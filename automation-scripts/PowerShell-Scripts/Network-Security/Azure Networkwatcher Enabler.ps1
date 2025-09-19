#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Networkwatcher Enabler

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Networkwatcher Enabler

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [string]$WENetworkWatcherName = " NetworkWatcher_$WELocation"
)

#region Functions

Write-WELog " Enabling Network Watcher in: $WELocation" " INFO"

; 
$WENetworkWatcher = Get-AzNetworkWatcher -ResourceGroupName $WEResourceGroupName -Name $WENetworkWatcherName -ErrorAction SilentlyContinue

if (-not $WENetworkWatcher) {
    # Create Network Watcher
   $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $WEResourceGroupName
       Name = $WENetworkWatcherName
       Location = $WELocation  Write-WELog "  Network Watcher created successfully:" " INFO
   }
   ; @params
} else {
    Write-WELog "  Network Watcher already exists:" " INFO"
}

Write-WELog "  Name: $($WENetworkWatcher.Name)" " INFO"
Write-WELog "  Location: $($WENetworkWatcher.Location)" " INFO"
Write-WELog "  Provisioning State: $($WENetworkWatcher.ProvisioningState)" " INFO"

Write-WELog " `nNetwork Watcher capabilities:" " INFO"
Write-WELog "  • IP Flow Verify" " INFO"
Write-WELog "  • Next Hop" " INFO"
Write-WELog "  • Security Group View" " INFO"
Write-WELog "  • VPN Diagnostics" " INFO"
Write-WELog "  • NSG Flow Logs" " INFO"
Write-WELog "  • Connection Monitor" " INFO"
Write-WELog "  • Packet Capture" " INFO"
Write-WELog "  • Connection Troubleshoot" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
