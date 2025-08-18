<#
.SYNOPSIS
    Windows Unsetenvvar

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


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $WEVariable
)
; 
$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest

Write-Information " Removing variable $WEVariable"
[Environment]::SetEnvironmentVariable(" $WEVariable" , $null, " Machine" )
Write-Information " Removing variable $WEVariable complete"


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
