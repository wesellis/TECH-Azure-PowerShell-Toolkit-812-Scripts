#Requires -Version 7.0

<#`n.SYNOPSIS
    Windows Unsetenvvar

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    [Parameter()]
    $Variable
)
#region Functions-Set-StrictMode -Version Latest
Write-Host "Removing variable $Variable"
[Environment]::SetEnvironmentVariable(" $Variable" ,
    [Parameter()]
    $null, "Machine" )
Write-Host "Removing variable $Variable complete"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


