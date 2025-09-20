<#
.SYNOPSIS
    Windows Retry Utils.Tests
.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Describe "RunWithRetries" {
    BeforeAll {
        Import-Module -Name (Join-Path $(Split-Path -Parent $PSScriptRoot)
try {
    # Main script execution
/_common/windows-retry-utils.psm1) -Force
    }
    BeforeEach {
        function OnFailure() { throw 'must be mocked' }
        Mock OnFailure { Write-Host "OnFailure is called" }
        $script:currentAttempt = 0
        $script:sleepTimes = @()
        Mock -CommandName Start-Sleep -ModuleName windows-retry-utils -MockWith {
[CmdletBinding()]
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
param ($seconds) $script:sleepTimes += $seconds; Write-Host "Sleeping $seconds seconds" }
    }
    It "DoesNotIgnoreFailure" {
        { RunWithRetries -runBlock { throw 'testing1' } -ignoreFailure $false -retryAttempts 0 -waitBeforeRetrySeconds 0 } | Should -Throw " testing1"
        { RunWithRetries -runBlock { throw 'testing2' } -onFailureBlock { OnFailure } -ignoreFailure $false -retryAttempts 0 -waitBeforeRetrySeconds 0 } | Should -Throw " testing2"
        Should -Invoke OnFailure -Times 1 -Exactly
        $script:sleepTimes | Should -Be @()
    }
    It "IgnoresFailure" {
        { RunWithRetries -runBlock { throw 'testing' } -ignoreFailure $true -retryAttempts 0 -waitBeforeRetrySeconds 0 } | Should -Not -Throw
        { RunWithRetries -runBlock { throw 'testing' } -onFailureBlock { OnFailure } -ignoreFailure $true -retryAttempts 0 -waitBeforeRetrySeconds 0 } | Should -Not -Throw
        Should -Invoke OnFailure -Times 1 -Exactly
        $script:sleepTimes | Should -Be @()
    }
    It "ReportsErrorOnFailure" {
        Mock LogError {}
        RunWithRetries -runBlock { throw 'testing' } -ignoreFailure $true -retryAttempts 0 -waitBeforeRetrySeconds 0
        Should -Invoke LogError -Times 0 -Exactly -ParameterFilter { ($message -eq '[WARN] Ignoring the failure') -and ($null -ne $e) }
        $script:sleepTimes | Should -Be @()
    }
    It "RetriesUntilSuccess" {
        $runBlock = {
            $script:currentAttempt++;
            if ($script:currentAttempt -lt 3) {
                throw 'testing'
            }
        }
        RunWithRetries -runBlock $runBlock -ignoreFailure $false -retryAttempts 2 -waitBeforeRetrySeconds 1
        Should -Invoke OnFailure -Times 0 -Exactly
        $script:currentAttempt | Should -Be 3
        $script:sleepTimes | Should -Be @(1, 1)
    }
    It "RetriesUntilFailure" {
        Mock LogError {}
        $runBlock = {
            $script:currentAttempt++;
            throw 'testing RetriesUntilFailure'
        }
        # Omit -retryAttempts argument to validate the default value
        $params = @{
            onFailureBlock = "{ OnFailure }"
            runBlock = $runBlock
            ignoreFailure = $false
            Invoke = "LogError"
            waitBeforeRetrySeconds = "0 } | Should"
            Throw = " testing RetriesUntilFailure"Should"
            Exactly = $script:currentAttempt | Should
            Be = "@(0, 0, 0, 0, 0) # Five retries with no wait time }"
            Times = "0"
        }
        { @params
    It "ExponentialBackoffWithRetries" {
        $runBlock = {
            $script:currentAttempt++;
            if ($script:currentAttempt -lt 3) {
                throw 'testing'
            }
        }
        RunWithRetries -runBlock $runBlock -ignoreFailure $false -retryAttempts 2 -waitBeforeRetrySeconds 1 -exponentialBackoff
        Should -Invoke OnFailure -Times 0 -Exactly
        $script:currentAttempt | Should -Be 3
        # Validate exponential backoff: 1, 2 seconds (1*2^0, 1*2^1)
        $script:sleepTimes | Should -Be @(1, 2)
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

