#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Expandosdisk

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
    $VerbosePreference = 'Continue'
function Resize-PartitionWithRetries {
    param(
        $DriveLetter
    )
    $size = Get-PartitionSupportedSize -DriveLetter $DriveLetter
    $MaxSize = $size.SizeMax
    Write-Verbose "Partition supported size for $($DriveLetter): $MaxSize"
    Get-Partition -DriveLetter $DriveLetter | Resize-Partition -Size $MaxSize
    Write-Verbose " $DriveLetter partition info after resize:"
    Get-Partition -DriveLetter $DriveLetter
}
    $RunBlock = {
    Resize-PartitionWithRetries -driveLetter 'C'
}
RunWithRetries -runBlock $RunBlock -retryAttempts 3 -waitBeforeRetrySeconds 5 -ignoreFailure $false
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
