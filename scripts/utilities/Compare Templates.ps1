#Requires -Version 7.4

<#
.SYNOPSIS
    Compare Templates

.DESCRIPTION
    Verifies that two JSON template files have the same hash (after removing generator metadata)

.PARAMETER TemplateFilePathExpected
    Path to the expected template file

.PARAMETER TemplateFilePathActual
    Path to the actual template file

.PARAMETER RemoveGeneratorMetadata
    Remove generator metadata before comparison

.PARAMETER WriteToHost
    Write output to host

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TemplateFilePathExpected,

    [Parameter(Mandatory = $true)]
    [string]$TemplateFilePathActual,

    [switch]$RemoveGeneratorMetadata,

    [switch]$WriteToHost
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    Import-Module "$PSScriptRoot/Local.psm1" -Force

    if ($WriteToHost) {
        Write-Output "Comparing $TemplateFilePathExpected and $TemplateFilePathActual"
    }

    $TemplateContentsExpectedRaw = Get-Content -ErrorAction Stop $TemplateFilePathExpected -Raw
    $TemplateContentsActualRaw = Get-Content -ErrorAction Stop $TemplateFilePathActual -Raw

    if ($RemoveGeneratorMetadata) {
        $TemplateContentsExpectedRaw = Remove-GeneratorMetadata -ErrorAction Stop $TemplateContentsExpectedRaw
        $TemplateContentsActualRaw = Remove-GeneratorMetadata -ErrorAction Stop $TemplateContentsActualRaw
    }

    $TemplateContentsExpected = Convert-StringToLines $TemplateContentsExpectedRaw
    $TemplateContentsActual = Convert-StringToLines $TemplateContentsActualRaw

    $diffs = Compare-Object $TemplateContentsExpected $TemplateContentsActual

    if ($diffs) {
        if ($WriteToHost) {
            Write-Warning "The templates do not match"
            Write-Verbose "`n`n************* ACTUAL CONTENTS ****************"
            Write-Verbose $TemplateContentsActualRaw
            Write-Verbose "***************** END OF ACTUAL CONTENTS ***************"
            Write-Output "`n`n************* EXPECTED CONTENTS ****************"
            Write-Output $TemplateContentsExpectedRaw
            Write-Output "***************** END OF EXPECTED CONTENTS ***************"
            Write-Output "`n`n************* DIFFERENCES (IGNORING METADATA) ****************`n"
            $diffs | Out-String | Write-Output
            Write-Output "`n***************** END OF DIFFERENCES ***************"
        }
        return $false
    }
    else {
        if ($WriteToHost) {
            Write-Output "Files are identical (not counting metadata)"
        }
        return $true
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}