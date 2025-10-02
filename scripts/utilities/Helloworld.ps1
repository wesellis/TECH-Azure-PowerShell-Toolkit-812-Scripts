#Requires -Version 7.4

<#
.SYNOPSIS
    Hello World

.DESCRIPTION
    Simple Hello World Azure automation script

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.EXAMPLE
    .\Helloworld.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Hello World!"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
