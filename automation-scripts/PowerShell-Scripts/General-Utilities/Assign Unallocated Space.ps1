<#
.SYNOPSIS
    Assign Unallocated Space

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Assign unallocated space to last partition on Disk.
    The OS disk size during image creation could be different (smaller) from the disk size assigned to a Dev Box definition.
    While creating ReFS drive, unallocated partition gets created because of this mismatch which needs to be assigned to existing drive.
    On first user logon this script will assign any unallocated space to last partition on that VM.
.PARAMETER TaskParams
    The parameters for the task when it is invoked from windows-configure-user-tasks\run-firstlogon-tasks.ps1.
.PARAMETER SuppressVerboseOutput
    Suppresses verbose output if set to $true.
    Sample Bicep snippet for using the artifact:
    {
      name: 'assign-unallocated-space'
      parameters: {
        DriveLetter: 'D'
      }
    }
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][PSObject] $TaskParams,
    [Parameter(Mandatory = $false)][bool] $SuppressVerboseOutput
)
Set-StrictMode -Version latest
function Invoke-AssignUnallocatedSpace {
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
        [Parameter(Mandatory = $true)][PSObject] $TaskParams,
        [Parameter(Mandatory = $false)][bool] $SuppressVerboseOutput
    )
    if (-not $SuppressVerboseOutput) {
        Write-Host " `nStarted with volumes:$(Get-Volume -ErrorAction Stop | Out-String)"
    }
    $driveLetter = $TaskParams.DriveLetter
    $supportedSize = Get-PartitionSupportedSize -DriveLetter $driveLetter
    $partition = Get-Partition -DriveLetter $driveLetter
    [Int32];  $maxSizeMB = $supportedSize.SizeMax / 1MB
    [Int32];  $currentSizeMB = $partition.Size / 1MB
    # Guard against error 'The size of the extent is less than the minimum of 1MB'
    if (($maxSizeMB - $currentSizeMB) -gt 1) {
        $partition | Resize-Partition -Size $supportedSize.SizeMax
        if (-not $SuppressVerboseOutput) {
            Write-Host " `nEnded with volumes:$(Get-Volume -ErrorAction Stop | Out-String)"
        }
    }
}
if (( -not(Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        Invoke-AssignUnallocatedSpace -TaskParams $TaskParams -SuppressVerboseOutput $SuppressVerboseOutput
    }
    catch {
        Write-Host " !!! [WARN] Unhandled exception (will be ignored):`n$_`n$($_.ScriptStackTrace)"
    }
}\n