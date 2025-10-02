#Requires -Version 7.4

<#
.SYNOPSIS
    Deployment Script Utils

.DESCRIPTION
    Azure automation utility functions for deployment operations
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.NOTES
    Provides retry functionality for deployment operations
    Supports exponential backoff and failure handling
#>

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'

function Invoke-WithRetries {
    <#
    .SYNOPSIS
        Executes a script block with retry logic

    .PARAMETER RunBlock
        The script block to execute

    .PARAMETER OnFailureBlock
        Script block to execute on failure

    .PARAMETER RetryAttempts
        Number of retry attempts

    .PARAMETER WaitBeforeRetrySeconds
        Seconds to wait before retry

    .PARAMETER IgnoreFailure
        Whether to ignore failures

    .PARAMETER ExponentialBackoff
        Whether to use exponential backoff
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ScriptBlock]$RunBlock,

        [ScriptBlock]$OnFailureBlock = {},

        [int]$RetryAttempts = 5,

        [int]$WaitBeforeRetrySeconds = 5,

        [bool]$IgnoreFailure = $false,

        [bool]$ExponentialBackoff = $true
    )

    [int]$RetriesLeft = $RetryAttempts

    while ($RetriesLeft -ge 0) {
        try {
            & $RunBlock
            break
        }
        catch {
            if ($RetriesLeft -le 0) {
                if ($OnFailureBlock) {
                    & $OnFailureBlock
                }
                if ($IgnoreFailure) {
                    Write-Output "[WARN] Ignoring the failure:`n$_`n$($_.ScriptStackTrace)"
                    break
                }
                else {
                    throw
                }
            }
            else {
                if ($ExponentialBackoff) {
                    $TotalDelay = [Math]::Pow(2, $RetryAttempts - $RetriesLeft) * $WaitBeforeRetrySeconds
                }
                else {
                    $TotalDelay = $WaitBeforeRetrySeconds
                }
                Write-Output "[WARN] Attempt failed: $_. Retrying in $TotalDelay seconds. Retries left: $RetriesLeft"
                $RetriesLeft--
                Start-Sleep -Seconds $TotalDelay
            }
        }
    }
}