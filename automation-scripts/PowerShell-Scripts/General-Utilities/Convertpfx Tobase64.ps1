<#
.SYNOPSIS
    Convertpfx Tobase64

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
    We Enhanced Convertpfx Tobase64

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    [string] [Parameter(mandatory = $true)] $pfxFile
)
; 
$fileContent = get-content -ErrorAction Stop " $pfxFile" -AsByteStream 
[System.Convert]::ToBase64String($fileContent) | Set-Content -Encoding ascii " $pfxFile.txt"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
