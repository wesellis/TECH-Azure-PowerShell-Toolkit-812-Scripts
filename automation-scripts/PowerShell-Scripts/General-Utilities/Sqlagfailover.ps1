<#
.SYNOPSIS
    Sqlagfailover

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
    [string] $Path
 )
 import-module sqlps
 Switch-SqlAvailabilityGroup -Path $Path -AllowDataLoss -force
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n