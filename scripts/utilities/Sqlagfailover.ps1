#Requires -Version 7.4

<#`n.SYNOPSIS
    Sqlagfailover

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
    [string] $Path
 )
 import-module sqlps
 Switch-SqlAvailabilityGroup -Path $Path -AllowDataLoss -force
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
