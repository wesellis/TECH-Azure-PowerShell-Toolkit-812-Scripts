<#
.SYNOPSIS
    Assign Unallocated Space

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
    We Enhanced Assign Unallocated Space

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
    Assign unallocated space to last partition on Disk. 
.DESCRIPTION
    The OS disk size during image creation could be different (smaller) from the disk size assigned to a Dev Box definition. 
    While creating ReFS drive, unallocated partition gets created because of this mismatch which needs to be assigned to existing drive. 
    On first user logon this script will assign any unallocated space to last partition on that VM. 
.PARAMETER TaskParams
    The parameters for the task when it is invoked from windows-configure-user-tasks\run-firstlogon-tasks.ps1.
.PARAMETER SuppressVerboseOutput
    Suppresses verbose output if set to $true.
.EXAMPLE
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
    [Parameter(Mandatory = $true)][PSObject] $WETaskParams,
    [Parameter(Mandatory = $false)][bool] $WESuppressVerboseOutput
)

Set-StrictMode -Version latest
$WEErrorActionPreference = " Stop"

function WE-Invoke-AssignUnallocatedSpace {
    

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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory = $true)][PSObject] $WETaskParams,
        [Parameter(Mandatory = $false)][bool] $WESuppressVerboseOutput
    )

    if (-not $WESuppressVerboseOutput) {
        Write-WELog " `nStarted with volumes:$(Get-Volume | Out-String)" " INFO"
    }

    $driveLetter = $WETaskParams.DriveLetter
    $supportedSize = Get-PartitionSupportedSize -DriveLetter $driveLetter
    $partition = Get-Partition -DriveLetter $driveLetter

    [Int32];  $maxSizeMB = $supportedSize.SizeMax / 1MB
    [Int32];  $currentSizeMB = $partition.Size / 1MB

    # Guard against error 'The size of the extent is less than the minimum of 1MB'
    if (($maxSizeMB - $currentSizeMB) -gt 1) {
        $partition | Resize-Partition -Size $supportedSize.SizeMax
        if (-not $WESuppressVerboseOutput) {
            Write-WELog " `nEnded with volumes:$(Get-Volume | Out-String)" " INFO"
        }
    }
}

if (( -not(Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    try {
        Invoke-AssignUnallocatedSpace -TaskParams $WETaskParams -SuppressVerboseOutput $WESuppressVerboseOutput
    }
    catch {
        Write-WELog " !!! [WARN] Unhandled exception (will be ignored):`n$_`n$($_.ScriptStackTrace)" " INFO"
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================