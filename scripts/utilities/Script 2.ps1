#Requires -Version 7.4

<#`n.SYNOPSIS
    Script 2

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
    [string] $Data
)
Write-Information \'this is what we got from the previous script:\'
Write-Output $Data
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
