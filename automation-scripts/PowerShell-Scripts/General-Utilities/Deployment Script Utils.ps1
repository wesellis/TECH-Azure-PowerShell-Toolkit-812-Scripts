<#
.SYNOPSIS
    Deployment Script Utils

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
    We Enhanced Deployment Script Utils

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
$WEProgressPreference = 'SilentlyContinue'

function WE-RunWithRetries(
    [ScriptBlock] $runBlock, 
    [ScriptBlock] $onFailureBlock = {}, 
    [int] $retryAttempts = 5, 
    [int] $waitBeforeRetrySeconds = 5,
    [bool] $ignoreFailure = $false,
    [bool] $exponentialBackoff = $true
) {
    [int] $retriesLeft = $retryAttempts

    while ($retriesLeft -ge 0) {
        try {
            & $runBlock
            break
        }
        catch {
            if ($retriesLeft -le 0) {
                if ($onFailureBlock) {
                    & $onFailureBlock
                }
                if ($ignoreFailure) {
                    Write-WELog " [WARN] Ignoring the failure:`n$_`n$($_.ScriptStackTrace)" " INFO"
                    break
                }
                else {
                    throw
                }
            }
            else {
                if ($exponentialBackoff) {
                   ;  $totalDelay = [Math]::Pow(2, $retryAttempts - $retriesLeft) * $waitBeforeRetrySeconds
                }
                else {
                   ;  $totalDelay = $waitBeforeRetrySeconds
                }
                Write-WELog " [WARN] Attempt failed: $_. Retrying in $totalDelay seconds. Retries left: $retriesLeft" " INFO"
                $retriesLeft--
                Start-Sleep -Seconds $totalDelay
            }
        }
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================