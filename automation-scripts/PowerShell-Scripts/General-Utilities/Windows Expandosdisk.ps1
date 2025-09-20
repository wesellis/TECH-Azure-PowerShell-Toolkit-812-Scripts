<#
.SYNOPSIS
    Windows Expandosdisk

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$VerbosePreference = 'Continue'
[CmdletBinding()]
function Resize-PartitionWithRetries {
    [CmdletBinding()
try {
    # Main script execution
]
param(
        [string]$driveLetter
    )
    $size = Get-PartitionSupportedSize -DriveLetter $driveLetter
$maxSize = $size.SizeMax
    Write-Verbose "Partition supported size for $($driveLetter): $maxSize"
    Get-Partition -DriveLetter $driveLetter | Resize-Partition -Size $maxSize
    Write-Verbose " $driveLetter partition info after resize:"
    Get-Partition -DriveLetter $driveLetter
}
Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-retry-utils.psm1');
$runBlock = {
    Resize-PartitionWithRetries -driveLetter 'C'
}
RunWithRetries -runBlock $runBlock -retryAttempts 3 -waitBeforeRetrySeconds 5 -ignoreFailure $false
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

