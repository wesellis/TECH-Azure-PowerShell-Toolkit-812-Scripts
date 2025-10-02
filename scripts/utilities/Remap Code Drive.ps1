#Requires -Version 7.4

<#`n.SYNOPSIS
    Remap Code Drive

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Remaps the CloudPC-designated D: ReFS/Dev Drive code drive to the original Q: drive used during image gen.
    Image prep creates the ReFS volume as Q: to avoid low letters like D: that can be mapped
    to a temp drive or virtual CD-ROM, and the N: drive reserved by the image builder.
    Image prep can update global environment variables to contain Q:, and build outputs and
    caches applied to repos on Q: can have full paths inside them that would be invalidated
    by a drive letter change.
.PARAMETER ToDriveLetter
    Final ReFS partition drive letter, defaults to 'Q'.
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][PSObject] $TaskParams
)
Set-StrictMode -Version Latest
function RemapCodeDrive($TaskParams) {
    $ToDriveLetter = $TaskParams.ToDriveLetter
    if (!$ToDriveLetter) {
    $ToDriveLetter = 'Q'
    }
    Write-Output " `nStarted with volumes:$(Get-Volume -ErrorAction Stop | Out-String)"
    $FirstReFSVolume = (Get-Volume -ErrorAction Stop | Where-Object { $_.FileSystemType -eq "ReFS" } | Select-Object -First 1)
    if (!$FirstReFSVolume) {
        throw "No ReFS drive found" ;
    }
    $FromDriveLetter = $FirstReFSVolume.DriveLetter
    if (!$FromDriveLetter) {
        throw "No ReFS drive letter found" ;
    }
    if ($ToDriveLetter -eq $FromDriveLetter) {
        Write-Output "Code drive letter ${ToDriveLetter} already matches the first ReFS/Dev Drive volume."
    }
    else {
        Write-Output "Reassigning code drive letter $FromDriveLetter to $ToDriveLetter"
        Set-Partition -DriveLetter $FromDriveLetter -NewDriveLetter $ToDriveLetter
    }
    Write-Output " `nEnded with volumes:$(Get-Volume -ErrorAction Stop | Out-String)"
    Write-Output "Checking dir contents of ${ToDriveLetter}: drive"
    Get-ChildItem -ErrorAction Stop ${ToDriveLetter}:
}
if (( -not(Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        RemapCodeDrive($TaskParams)
    }
    catch {
        Write-Output " !!! [WARN] Unhandled exception (will be ignored):`n$_`n$($_.ScriptStackTrace)"
    }
`n}
