#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Setenvvar

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
    $Variable,
    [Parameter()]
    $Value,
    [Parameter()]
    $PrintValue = " true"
)
Write-Output $(if ($PrintValue -eq " true" ) { "Setting variable $Variable with value $Value" } else { "Setting variable $Variable" })
[Environment]::SetEnvironmentVariable(" $Variable" , "$Value" , "Machine" )
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
