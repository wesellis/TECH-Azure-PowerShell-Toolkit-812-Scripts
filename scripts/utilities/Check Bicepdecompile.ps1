#Requires -Version 7.4

<#
.SYNOPSIS
    Check Bicep Decompile output

.DESCRIPTION
    Detects unwanted raw output from bicep decompile command and identifies files that need cleanup

.PARAMETER SampleFolder
    Path to the folder containing Bicep files to check

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleFolder = $ENV:SAMPLE_FOLDER
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    if ([string]::IsNullOrWhiteSpace($SampleFolder)) {
        throw "SampleFolder parameter is required. Please provide a valid path."
    }

    Write-Output "Finding all bicep files in: $SampleFolder"
    Write-Verbose "Searching for *.bicep files recursively"

    $BicepFiles = Get-ChildItem -Path "$SampleFolder\*.bicep" -Recurse
    Write-Verbose "Found $($BicepFiles.Count) Bicep files to analyze"

    $issuesFound = $false

    foreach ($f in $BicepFiles) {
        Write-Verbose "Analyzing file: $($f.FullName)"
        $BicepText = Get-Content -Path $f.FullName -Raw

        $matches = $BicepText | Select-String -Pattern "resource \w{1,}_resource | \w{1,}_var | \w{1,}_param | \s\w{1,}_id\s" -AllMatches

        if ($matches) {
            $issuesFound = $true
            foreach ($match in $matches.Matches) {
                Write-Warning "$($f.Name) may contain raw output from decompile, please clean up: $($match.Value)"
                Write-Output "##vso[task.setvariable variable=label.decompile.clean-up.needed]$true"
            }
        }
    }

    if (-not $issuesFound) {
        Write-Output "No decompile cleanup issues found in Bicep files"
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}