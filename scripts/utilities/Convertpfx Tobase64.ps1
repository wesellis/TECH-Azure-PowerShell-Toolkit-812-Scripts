#Requires -Version 7.0

<#`n.SYNOPSIS
    Convertpfx Tobase64

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
    [string] [Parameter(mandatory = $true)] $pfxFile
)
#region Functions
$fileContent = get-content -ErrorAction Stop " $pfxFile" -AsByteStream
[System.Convert]::ToBase64String($fileContent) | Set-Content -Encoding ascii " $pfxFile.txt"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
