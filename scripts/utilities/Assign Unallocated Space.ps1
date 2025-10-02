#Requires -Version 7.4

<#
.SYNOPSIS
    Assign Unallocated Space

.DESCRIPTION
    Azure automation script to assign unallocated disk space to the last partition
    on a disk. Useful for Dev Box scenarios where OS disk size during image creation
    may differ from the disk size assigned in the definition.

.PARAMETER TaskParams
    The parameters for the task when invoked from windows-configure-user-tasks

.PARAMETER SuppressVerboseOutput
    Suppresses verbose output if set to $true

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [PSObject]$TaskParams,

    [Parameter(Mandatory = $false)]
    [bool]$SuppressVerboseOutput
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $logEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

function Invoke-AssignUnallocatedSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$TaskParams,

        [Parameter(Mandatory = $false)]
        [bool]$SuppressVerboseOutput
    )

    if (-not $SuppressVerboseOutput) {
        Write-ColorOutput "Started with volumes:" -Level INFO
        Get-Volume -ErrorAction Stop | Out-String | Write-Output
    }

    $driveLetter = $TaskParams.DriveLetter

    try {
        $supportedSize = Get-PartitionSupportedSize -DriveLetter $driveLetter -ErrorAction Stop
        $partition = Get-Partition -DriveLetter $driveLetter -ErrorAction Stop

        [Int32]$maxSizeMB = $supportedSize.SizeMax / 1MB
        [Int32]$currentSizeMB = $partition.Size / 1MB

        if (($maxSizeMB - $currentSizeMB) -gt 1) {
            Write-ColorOutput "Resizing partition $driveLetter from $currentSizeMB MB to $maxSizeMB MB" -Level INFO
            $partition | Resize-Partition -Size $supportedSize.SizeMax -ErrorAction Stop
            Write-ColorOutput "Successfully resized partition" -Level SUCCESS

            if (-not $SuppressVerboseOutput) {
                Write-ColorOutput "Ended with volumes:" -Level INFO
                Get-Volume -ErrorAction Stop | Out-String | Write-Output
            }
        }
        else {
            Write-ColorOutput "No unallocated space to assign (difference: $(($maxSizeMB - $currentSizeMB)) MB)" -Level INFO
        }
    }
    catch {
        Write-ColorOutput "Error processing partition: $_" -Level ERROR
        throw
    }
}

if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        Invoke-AssignUnallocatedSpace -TaskParams $TaskParams -SuppressVerboseOutput $SuppressVerboseOutput
    }
    catch {
        Write-ColorOutput "Unhandled exception (will be ignored): $_`n$($_.ScriptStackTrace)" -Level WARN
    }
}