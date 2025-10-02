#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Set Devdriveconfiguration

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Updates Dev Drive configuration. Requires that the Dev Drive feature be enabled, and if applicable
    a reboot performed, prior to calling this script.
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
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [Parameter(Mandatory = $true)][bool] $EnableGVFS,
    [Parameter(Mandatory = $true)][bool] $EnableContainers
)
Set-StrictMode -Version Latest
Write-Output ""
Write-Output "Check that /DrvDrv parameter is visible on format command."
format /?
Write-Output "Setting Dev Drive group policies and settings."
    $AllowedFilterList = "MsSecFlt,ProcMon24"
if ($EnableGVFS) {
    $AllowedFilterList = $AllowedFilterList + " ,PrjFlt"
}
if ($EnableContainers) {
    $AllowedFilterList = $AllowedFilterList + " ,wcifs,bindFlt"
}
Write-Output ""
Write-Output "Allowing the following filesystem filter drivers to mount to any Dev Drive:"
Write-Output "  $AllowedFilterList"
fsutil devdrv setFiltersAllowed $AllowedFilterList
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
