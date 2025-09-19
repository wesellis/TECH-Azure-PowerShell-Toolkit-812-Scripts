#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Set Devdriveconfiguration

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
    We Enhanced Windows Set Devdriveconfiguration

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS
    Updates Dev Drive configuration. Requires that the Dev Drive feature be enabled, and if applicable
    a reboot performed, prior to calling this script.
.DESCRIPTION
    Uses `fsutil devdrv` to set optional Windows filter drivers allowed to attach to Dev Drive.
    The default for Dev Drive is to allow a very small list, which is how it gains performance -
    the more filter drivers, the more kernel callbacks in the chain-of-responsibility for every single
    filesystem call. The list of drivers added by the caller should be as minimal as possible.
    Note that the driver list set by fsutil adds to any default list set by Group Policy.
.PARAMETER EnableGVFS
    When set, the PrjFlt filesystem minifilter driver is allowed on the Dev Drive.
    This supports use of GVFS/VFSForGit repo enlistments at the cost of reduced Dev Drive performance.
.PARAMETER EnableContainers
    When set, the wcifs and bindflt filesystem minifilter drivers are allowed on the Dev Drive.
    This supports mounting Windows containers on the Dev Drive at the cost of reduced Dev Drive performance.


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][bool] $WEEnableGVFS,
    [Parameter(Mandatory = $true)][bool] $WEEnableContainers
)

#region Functions
; 
$WEErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-WELog "" " INFO"
Write-WELog " Check that /DrvDrv parameter is visible on format command." " INFO"
format /?

Write-WELog " Setting Dev Drive group policies and settings." " INFO"

; 
$WEAllowedFilterList = " MsSecFlt,ProcMon24"
if ($WEEnableGVFS) {
    $WEAllowedFilterList = $WEAllowedFilterList + " ,PrjFlt"
}
if ($WEEnableContainers) {
   ;  $WEAllowedFilterList = $WEAllowedFilterList + " ,wcifs,bindFlt"
}
Write-WELog "" " INFO"
Write-WELog " Allowing the following filesystem filter drivers to mount to any Dev Drive:" " INFO"
Write-WELog "  $WEAllowedFilterList" " INFO"
fsutil devdrv setFiltersAllowed $WEAllowedFilterList



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
