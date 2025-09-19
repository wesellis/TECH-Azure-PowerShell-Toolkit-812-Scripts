#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Unsetenvvar

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

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
    Wes Ellis (wes@wesellis.com)

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

#region Functions
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


#endregion
