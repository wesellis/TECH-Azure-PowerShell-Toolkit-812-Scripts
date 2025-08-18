<#
.SYNOPSIS
    Remap Code Drive

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Remap Code Drive

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS
    Remaps the CloudPC-designated D: ReFS/Dev Drive code drive to the original Q: drive used during image gen.
.DESCRIPTION
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
    [Parameter(Mandatory = $true)][PSObject] $WETaskParams
)

$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest

function WE-RemapCodeDrive($WETaskParams) {
    $WEToDriveLetter = $WETaskParams.ToDriveLetter
    if (!$WEToDriveLetter) {
       ;  $WEToDriveLetter = 'Q'
    }

    # FileSystemType ReFS applies to Dev Drive as well, which is a special " Trusted" mode of ReFS.
    Write-WELog " `nStarted with volumes:$(Get-Volume -ErrorAction Stop | Out-String)" " INFO"
   ;  $WEFirstReFSVolume = (Get-Volume -ErrorAction Stop | Where-Object { $_.FileSystemType -eq " ReFS" } | Select-Object -First 1)
    if (!$WEFirstReFSVolume) {
        throw " No ReFS drive found" ;
    }

    $WEFromDriveLetter = $WEFirstReFSVolume.DriveLetter
    if (!$WEFromDriveLetter) {
        throw " No ReFS drive letter found" ;
    }

    if ($WEToDriveLetter -eq $WEFromDriveLetter) {
        Write-WELog " Code drive letter ${ToDriveLetter} already matches the first ReFS/Dev Drive volume." " INFO"
    }
    else {
        Write-WELog " Reassigning code drive letter $WEFromDriveLetter to $WEToDriveLetter" " INFO"
        Set-Partition -DriveLetter $WEFromDriveLetter -NewDriveLetter $WEToDriveLetter
    }

    Write-WELog " `nEnded with volumes:$(Get-Volume -ErrorAction Stop | Out-String)" " INFO"

    # This will mount the drive and open a handle to it.
    Write-WELog " Checking dir contents of ${ToDriveLetter}: drive" " INFO"
    Get-ChildItem -ErrorAction Stop ${ToDriveLetter}:
}

if (( -not(Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        # Unit-testable function - place all real logic there.
        RemapCodeDrive($WETaskParams)
    }
    catch {
        Write-WELog " !!! [WARN] Unhandled exception (will be ignored):`n$_`n$($_.ScriptStackTrace)" " INFO"
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================