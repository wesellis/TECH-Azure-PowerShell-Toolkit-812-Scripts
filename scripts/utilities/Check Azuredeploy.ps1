#Requires -Version 7.4

<#
.SYNOPSIS
    Check Azure Deploy configuration

.DESCRIPTION
    Checks for missing azuredeploy.json files in Bicep project directories

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    Write-Verbose "Searching for main.bicep files"
    $bicep = Get-ChildItem -Path "main.bicep" -Recurse

    Write-Verbose "Found $($bicep.Count) Bicep files to check"

    foreach ($b in $bicep) {
        $path = $b.FullName | Split-Path -Parent

        if (!(Test-Path "$path\azuredeploy.json")) {
            if ($($b.fullname) -notlike "*ci-tests*") {
                Write-Error "$($b.FullName) is missing azuredeploy.json"
            } else {
                Write-Verbose "Skipping CI test file: $($b.FullName)"
            }
        } else {
            Write-Verbose "Found azuredeploy.json for: $($b.FullName)"
        }
    }

    Write-Output "Azure deploy check completed successfully"
}
catch {
    Write-Error "Failed to check Azure deploy configuration: $($_.Exception.Message)"
    throw
}