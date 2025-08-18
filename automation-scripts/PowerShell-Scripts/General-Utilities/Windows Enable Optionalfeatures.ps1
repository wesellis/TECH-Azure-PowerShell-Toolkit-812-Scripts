<#
.SYNOPSIS
    Windows Enable Optionalfeatures

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Windows Enable Optionalfeatures

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $WEFeatureName
    
)
; 
$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest; 
$WEVerbosePreference = 'Continue'

Enable-WindowsOptionalFeature -Online -FeatureName $WEFeatureName -NoRestart -All


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
