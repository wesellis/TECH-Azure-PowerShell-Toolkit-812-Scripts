#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Create Refs

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Create ReFS or Dev Drive "x" drive volume.
    Create ReFS or Dev Drive " x" drive volume. If " x" volume already exists then delete it before creating " x" .
.PARAMETER DevBoxRefsDrive (optional)
    Drive letter. Defaults to 'Q' to avoid the low drive letters that may already be taken by an Azure VM.
.PARAMETER OsDriveMinSizeGB (optional)
    The required minimum size of NTFS C drive in GB when ReFS or Dev Drive volume is created.
.PARAMETER IsDevDrive (optional)
    Whether the ReFS drive is to be formatted as a Dev Drive. Requires a compatible Win11 22H2+ October 2023 or later base image.
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
    [string] $DevBoxRefsDrive = "Q" ,
    [int] $OsDriveMinSizeGB = 160,
    [bool] $IsDevDrive = $false
)
Set-StrictMode -Version latest
Write-Output " `nSTART: $(Get-Date -Format u)"
function FindOrCreateReFSOrDevDriveVolume([string] $DevBoxRefsDrive, [int] $OsDriveMinSizeGB, [bool] $IsDevDrive, [string] $TempDir) {
    Write-Output " `nStarted with volumes:$(Get-Volume -ErrorAction Stop | Out-String)"
    $FirstReFSVolume = (Get-Volume -ErrorAction Stop | Where-Object { $_.FileSystemType -eq "ReFS" } | Select-Object -First 1)
    if ($FirstReFSVolume) {
    $FromDriveLetterOrNull = $FirstReFSVolume.DriveLetter
        if ($DevBoxRefsDrive -eq $FromDriveLetterOrNull) {
            Write-Output "Code drive letter ${DevBoxRefsDrive} already matches the first ReFS/Dev Drive volume."
        }
        else {
            Write-Output "Assigning code drive letter to $DevBoxRefsDrive"
    $FirstReFSVolume | Get-Partition -ErrorAction Stop | Set-Partition -NewDriveLetter $DevBoxRefsDrive
        }
        Write-Output " `nDone with volumes:$(Get-Volume -ErrorAction Stop | Out-String)"
        Write-Output "Checking dir contents of ${DevBoxRefsDrive}: drive"
        Get-ChildItem -ErrorAction Stop ${DevBoxRefsDrive}:
        return
    }
    $CSizeGB = (Get-Volume -ErrorAction Stop C).Size / 1024 / 1024 / 1024
    $TargetReFSSizeGB = [math]::Floor($CSizeGB - $OsDriveMinSizeGB)
    $DiffGB = $CSizeGB - $TargetReFSSizeGB
    Write-Output "Target ReFS size $TargetReFSSizeGB GB, current C: size $CSizeGB GB"
    if ($DiffGB -lt 50) {
        throw "ReFS/Dev Drive target size $TargetReFSSizeGB GB would leave less than 50 GB free on drive C: which is not enough for Windows and apps. Drive C: size $CSizeGB GB"
    }
    if ($TargetReFSSizeGB -lt 20) {
        throw "ReFS/Dev Drive target size $TargetReFSSizeGB GB is below the min size 20 GB. Drive C: size $CSizeGB GB"
    }
    $TargetReFSSizeMB = $TargetReFSSizeGB * 1024
    if ((Get-PSDrive).Name -match " ^" + $DevBoxRefsDrive + " $" ) {
    $DiskPartDeleteScriptPath = $TempDir + "/CreateReFSDelExistingVolume.txt"
    $rmcmd = "SELECT DISK 0 `r`n SELECT VOLUME=$DevBoxRefsDrive `r`n DELETE VOLUME OVERRIDE"
    $rmcmd | Set-Content -Path $DiskPartDeleteScriptPath
        Write-Output "Delete existing $DevBoxRefsDrive `r`n $rmcmd"
        diskpart /s $DiskPartDeleteScriptPath
    $ExitCode = $LASTEXITCODE
        if ($ExitCode -eq 0) {
            Write-Output "Successfully deleted existing $DevBoxRefsDrive volume"
        }
        else {
            Write-Error "[ERROR] Delete volume diskpart command failed with exit code: $ExitCode" -ErrorAction Stop
        }
    }
    $DiskPartScriptPath = $TempDir + "/CreateReFSFromExistingVolume.txt"
    $cmd = "SELECT VOLUME C: `r`n SHRINK desired = $TargetReFSSizeMB minimum = $TargetReFSSizeMB `r`n CREATE PARTITION PRIMARY `r`n ASSIGN LETTER=$DevBoxRefsDrive `r`n"
    $cmd | Set-Content -Path $DiskPartScriptPath
    Write-Output "Creating $DevBoxRefsDrive ReFS volume: diskpart:`r`n $cmd"
    diskpart /s $DiskPartScriptPath
    $ExitCode = $LASTEXITCODE
    if ($ExitCode -eq 0) {
        Write-Output "Successfully created ReFS $DevBoxRefsDrive volume"
    }
    else {
        Write-Error "[ERROR] ReFS volume creation command failed with exit code: $ExitCode" -ErrorAction Stop
    }
    $DevBoxDriveWithColon = " ${DevBoxRefsDrive}:"
    $DevDriveParam = ""
    $DriveLabel = "ReFS"
    if ($IsDevDrive) {
    $DevDriveParam = "/DevDrv"
    $DriveLabel = "DevDrive"
    }
    Run-Program format " $DevBoxDriveWithColon /q /y /FS:ReFS $DevDriveParam /V:$DriveLabel" -RetryAttempts 1
    Write-Output "Successfully formatted ReFS $DevBoxRefsDrive volume. Final volume list:"
    Get-Volume -ErrorAction Stop | Out-String
}
if (( -not(Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        FindOrCreateReFSOrDevDriveVolume $DevBoxRefsDrive $OsDriveMinSizeGB $IsDevDrive $env:TEMP
    } catch {
        Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
    }
`n}
