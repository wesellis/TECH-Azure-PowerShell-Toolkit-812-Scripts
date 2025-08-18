<#
.SYNOPSIS
    We Enhanced Windows Unsetenvvar

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

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    $WEVariable
)

$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

write-host " Removing variable $WEVariable"
[Environment]::SetEnvironmentVariable(" $WEVariable", $null, " Machine")
write-host " Removing variable $WEVariable complete"

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
