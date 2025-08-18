<#
.SYNOPSIS
    Windows Expandosdisk

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
    We Enhanced Windows Expandosdisk

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$WEVerbosePreference = 'Continue'

[CmdletBinding()]
function WE-Resize-PartitionWithRetries {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = " Stop"
[CmdletBinding()]
param(
        [string]$driveLetter
    )
    $size = Get-PartitionSupportedSize -DriveLetter $driveLetter
   ;  $maxSize = $size.SizeMax
    Write-Verbose " Partition supported size for $($driveLetter): $maxSize"
    Get-Partition -DriveLetter $driveLetter | Resize-Partition -Size $maxSize
    Write-Verbose " $driveLetter partition info after resize:"
    Get-Partition -DriveLetter $driveLetter
}

Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-retry-utils.psm1'); 
$runBlock = {
    Resize-PartitionWithRetries -driveLetter 'C'
}

RunWithRetries -runBlock $runBlock -retryAttempts 3 -waitBeforeRetrySeconds 5 -ignoreFailure $false


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
