#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Unsetenvvar

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
    [Parameter()]
    $Variable
)
Write-Output "Removing variable $Variable"
[Environment]::SetEnvironmentVariable(" $Variable" ,
    [Parameter()]
    $null, "Machine" )
Write-Output "Removing variable $Variable complete"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
