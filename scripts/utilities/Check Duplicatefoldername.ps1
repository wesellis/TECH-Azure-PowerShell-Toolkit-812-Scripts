#Requires -Version 7.4

<#
.SYNOPSIS
    Check for duplicate folder names

.DESCRIPTION
    This script checks for duplicate sample folder names that could cause issues with URL fragments
    in documentation samples. Duplicate folder names will cause ingestion failures.

.PARAMETER SampleFolder
    Path to the sample folder to check

.PARAMETER SampleName
    Name of the sample to check for duplicates

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleFolder = $ENV:SAMPLE_FOLDER,

    [Parameter()]
    [string]$SampleName = $ENV:SAMPLE_NAME
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    if ([string]::IsNullOrWhiteSpace($SampleName)) {
        throw "SampleName parameter is required"
    }

    Write-Verbose "Checking for duplicate folder names for sample: $SampleName"

    $fragment = if ($SampleName.StartsWith('modules')) {
        Write-Verbose "Module sample detected, skipping duplicate check"
        return
    } else {
        $SampleName.Split('\')[-1]
    }

    Write-Verbose "Searching for directories with name: $fragment"
    $duplicateDirectories = Get-ChildItem -Directory -Recurse -Filter $fragment

    Write-Output "Found directories: $($duplicateDirectories.FullName -join ', ')"

    if ($duplicateDirectories.Count -gt 1) {
        Write-Warning "Duplicate folder names found:"
        foreach ($dir in $duplicateDirectories) {
            Write-Output "  - $($dir.FullName)"
        }
        Write-Output "##vso[task.setvariable variable=duplicate.folderName]$true"
    } else {
        Write-Output "No duplicate folder names found"
        Write-Verbose "Single directory found at: $($duplicateDirectories.FullName)"
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}