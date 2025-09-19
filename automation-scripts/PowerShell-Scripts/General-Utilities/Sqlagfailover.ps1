#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Sqlagfailover

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
    We Enhanced Sqlagfailover

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
    [string] $WEPath
 )
 import-module sqlps
 Switch-SqlAvailabilityGroup -Path $WEPath -AllowDataLoss -force



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
