#Requires -Version 7.0

<#`n.SYNOPSIS
    Script 2

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
    [string] $Data
)
Write-Information \'this is what we got from the previous script:\'
Write-Host $Data
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
