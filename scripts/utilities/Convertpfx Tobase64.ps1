#Requires -Version 7.4

<#
.SYNOPSIS
    Convert PFX to Base64

.DESCRIPTION
    Azure automation script to convert a PFX certificate file to Base64 encoded string.
    The Base64 output is saved to a text file with the same name as the input file plus .txt extension.

.PARAMETER PfxFile
    Path to the PFX certificate file to convert

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$PfxFile
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Converting PFX file to Base64: $PfxFile"

    # Read the PFX file as byte array
    $FileContent = Get-Content -Path $PfxFile -AsByteStream -ErrorAction Stop

    # Convert to Base64 and save to text file
    $OutputFile = "$PfxFile.txt"
    [System.Convert]::ToBase64String($FileContent) | Set-Content -Path $OutputFile -Encoding ASCII

    Write-Output "Base64 conversion completed. Output saved to: $OutputFile"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}