<#
.SYNOPSIS
    Windows Create Refs

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
    We Enhanced Windows Create Refs

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
    Create ReFS or Dev Drive "x" drive volume. 
.DESCRIPTION
    Create ReFS or Dev Drive " x" drive volume. If " x" volume already exists then delete it before creating " x" .
.PARAMETER DevBoxRefsDrive (optional)
    Drive letter. Defaults to 'Q' to avoid the low drive letters that may already be taken by an Azure VM.
.PARAMETER OsDriveMinSizeGB (optional)
    The required minimum size of NTFS C drive in GB when ReFS or Dev Drive volume is created.
.PARAMETER IsDevDrive (optional)
    Whether the ReFS drive is to be formatted as a Dev Drive. Requires a compatible Win11 22H2+ October 2023 or later base image.

.EXAMPLE
    Sample Bicep snippet for using the artifact:

    {
      name: 'windows-create-ReFS'
      parameters: {
        DevBoxRefsDrive: 'Q'
        OsDriveMinSizeGB: 80
        IsDevDrive: true
      }
    }


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] $WEDevBoxRefsDrive = " Q" ,
    [int] $WEOsDriveMinSizeGB = 160,
    [bool] $WEIsDevDrive = $false
)

Set-StrictMode -Version latest
$WEErrorActionPreference = " Stop"

Write-WELog " `nSTART: $(Get-Date -Format u)" " INFO"

function WE-FindOrCreateReFSOrDevDriveVolume([string] $WEDevBoxRefsDrive, [int] $WEOsDriveMinSizeGB, [bool] $WEIsDevDrive, [string] $WETempDir) {
    Write-WELog " `nStarted with volumes:$(Get-Volume | Out-String)" " INFO"

    # Check whether Dev Drive volume already exists, i.e. has already been created in the base image.
    $firstReFSVolume = (Get-Volume | Where-Object { $_.FileSystemType -eq " ReFS" } | Select-Object -First 1)
    if ($firstReFSVolume) {
        $fromDriveLetterOrNull = $firstReFSVolume.DriveLetter
        if ($WEDevBoxRefsDrive -eq $fromDriveLetterOrNull) {
            Write-WELog " Code drive letter ${DevBoxRefsDrive} already matches the first ReFS/Dev Drive volume." " INFO"
        }
        else {
            Write-WELog " Assigning code drive letter to $WEDevBoxRefsDrive" " INFO"
            $firstReFSVolume | Get-Partition | Set-Partition -NewDriveLetter $WEDevBoxRefsDrive
        }
    
        Write-WELog " `nDone with volumes:$(Get-Volume | Out-String)" " INFO"
    
        # This will mount the drive and open a handle to it which is important to get the drive ready.
        Write-WELog " Checking dir contents of ${DevBoxRefsDrive}: drive" " INFO"
        Get-ChildItem ${DevBoxRefsDrive}:
        return
    }

    $cSizeGB = (Get-Volume C).Size / 1024 / 1024 / 1024
    $targetReFSSizeGB = [math]::Floor($cSizeGB - $WEOsDriveMinSizeGB)
    $diffGB = $cSizeGB - $targetReFSSizeGB
    Write-WELog " Target ReFS size $targetReFSSizeGB GB, current C: size $cSizeGB GB" " INFO"
    # Sanity checks
    if ($diffGB -lt 50) {
        throw " ReFS/Dev Drive target size $targetReFSSizeGB GB would leave less than 50 GB free on drive C: which is not enough for Windows and apps. Drive C: size $cSizeGB GB"
    }
    if ($targetReFSSizeGB -lt 20) {
        throw " ReFS/Dev Drive target size $targetReFSSizeGB GB is below the min size 20 GB. Drive C: size $cSizeGB GB"
    }

    $targetReFSSizeMB = $targetReFSSizeGB * 1024

    if ((Get-PSDrive).Name -match " ^" + $WEDevBoxRefsDrive + " $" ) {
        $WEDiskPartDeleteScriptPath = $WETempDir + " /CreateReFSDelExistingVolume.txt"
        $rmcmd = " SELECT DISK 0 `r`n SELECT VOLUME=$WEDevBoxRefsDrive `r`n DELETE VOLUME OVERRIDE"
        $rmcmd | Set-Content -Path $WEDiskPartDeleteScriptPath
        Write-WELog " Delete existing $WEDevBoxRefsDrive `r`n $rmcmd" " INFO"
        diskpart /s $WEDiskPartDeleteScriptPath
        $exitCode = $WELASTEXITCODE
        if ($exitCode -eq 0) {
            Write-WELog " Successfully deleted existing $WEDevBoxRefsDrive volume" " INFO" 
        }
        else {
            Write-Error " [ERROR] Delete volume diskpart command failed with exit code: $exitCode" -ErrorAction Stop
        }
    }
    
    # https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shrink
    $WEDiskPartScriptPath = $WETempDir + " /CreateReFSFromExistingVolume.txt"
    $cmd = " SELECT VOLUME C: `r`n SHRINK desired = $targetReFSSizeMB minimum = $targetReFSSizeMB `r`n CREATE PARTITION PRIMARY `r`n ASSIGN LETTER=$WEDevBoxRefsDrive `r`n"
    $cmd | Set-Content -Path $WEDiskPartScriptPath
    Write-WELog " Creating $WEDevBoxRefsDrive ReFS volume: diskpart:`r`n $cmd" " INFO"
    diskpart /s $WEDiskPartScriptPath
    $exitCode = $WELASTEXITCODE
    if ($exitCode -eq 0) {
        Write-WELog " Successfully created ReFS $WEDevBoxRefsDrive volume" " INFO"
    }
    else {
        Write-Error " [ERROR] ReFS volume creation command failed with exit code: $exitCode" -ErrorAction Stop
    }

    $WEDevBoxDriveWithColon = " ${DevBoxRefsDrive}:"
    $WEDevDriveParam = ""
    $WEDriveLabel = " ReFS"
    if ($WEIsDevDrive) {
       ;  $WEDevDriveParam = " /DevDrv"
       ;  $WEDriveLabel = " DevDrive"
    }
    Run-Program format " $WEDevBoxDriveWithColon /q /y /FS:ReFS $WEDevDriveParam /V:$WEDriveLabel" -RetryAttempts 1
    Write-WELog " Successfully formatted ReFS $WEDevBoxRefsDrive volume. Final volume list:" " INFO"
    Get-Volume | Out-String
}

Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-run-program.psm1') -DisableNameChecking
if (( -not(Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        FindOrCreateReFSOrDevDriveVolume $WEDevBoxRefsDrive $WEOsDriveMinSizeGB $WEIsDevDrive $env:TEMP
    } catch {
        Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================