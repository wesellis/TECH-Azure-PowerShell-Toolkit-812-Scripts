#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Vm List All

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
    We Enhanced Azure Vm List All

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

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [string]$WESubscriptionId
)

#region Functions

if ($WESubscriptionId) {
    Set-AzContext -SubscriptionId $WESubscriptionId
    Write-Information -Object " Connected to subscription: $WESubscriptionId"
}

Write-Information -Object " Retrieving all VMs across subscription..."
; 
$WEVMs = Get-AzVM -Status
Write-Information -Object " `nFound $($WEVMs.Count) Virtual Machines:"
Write-Information -Object (" =" * 60)

foreach ($WEVM in $WEVMs) {
    Write-Information -Object " VM: $($WEVM.Name) | RG: $($WEVM.ResourceGroupName) | State: $($WEVM.PowerState) | Size: $($WEVM.HardwareProfile.VmSize)"
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
