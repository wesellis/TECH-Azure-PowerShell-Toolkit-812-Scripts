#Requires -Version 7.4

<#`n.SYNOPSIS
    Run Artifact Test

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [String] $StrParam,
    [Int] $IntParam,
    [Boolean] $BoolParam
)
Write-Output " -- Received params: StrParam=$StrParam, IntParam=$IntParam, BoolParam=$BoolParam"
    $script:TestResults = @{
    StrParam  = $StrParam
    IntParam  = $IntParam
    BoolParam = $BoolParam
    PSScriptRoot = $PSScriptRoot
}
if ((Test-Path variable:global:TestShouldThrow) -and $global:TestShouldThrow) {
    throw "Test should throw"
}
if ((Test-Path variable:global:TestShouldExitWithNonZeroExitCode) -and ($global:TestShouldExitWithNonZeroExitCode -ne 0)) {
    cmd.exe /c dir 'Y:\path\does
ot\exist'
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
