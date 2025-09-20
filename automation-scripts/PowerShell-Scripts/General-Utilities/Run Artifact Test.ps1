<#
.SYNOPSIS
    Run Artifact Test

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [String] $StrParam,
    [Int] $IntParam,
    [Boolean] $BoolParam
)
#region Functions
Set-StrictMode -Version Latest
Write-Host " -- Received params: StrParam=$StrParam, IntParam=$IntParam, BoolParam=$BoolParam"
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
    cmd.exe /c dir 'Y:\path\does\not\exist'
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

