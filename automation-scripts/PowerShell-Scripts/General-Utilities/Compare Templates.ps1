<#
.SYNOPSIS
    Compare Templates

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
Verifies that two JSON template files have the same hash (after removing generator metadata)
try {
    # Main script execution
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string][Parameter(mandatory = $true)] $TemplateFilePathExpected,
    [string][Parameter(mandatory = $true)] $TemplateFilePathActual,
    [switch] $RemoveGeneratorMetadata,
    [switch] $WriteToHost
)
Import-Module " $PSScriptRoot/Local.psm1" -Force
if ($WriteToHost) {
    Write-Host "Comparing $TemplateFilePathExpected and $TemplateFilePathActual"
}
$templateContentsExpectedRaw = Get-Content -ErrorAction Stop $TemplateFilePathExpected -Raw
$templateContentsActualRaw = Get-Content -ErrorAction Stop $TemplateFilePathActual -Raw
if ($RemoveGeneratorMetadata) {
    $templateContentsExpectedRaw = Remove-GeneratorMetadata -ErrorAction Stop $templateContentsExpectedRaw
    $templateContentsActualRaw = Remove-GeneratorMetadata -ErrorAction Stop $templateContentsActualRaw
}
$templateContentsExpected = Convert-StringToLines $templateContentsExpectedRaw;
$templateContentsActual = Convert-StringToLines $templateContentsActualRaw
$diffs = Compare-Object $templateContentsExpected $templateContentsActual
if ($diffs) {
    if ($WriteToHost) {
        Write-Warning "The templates do not match"
        Write-Verbose " `n`n************* ACTUAL CONTENTS ****************"
        Write-Verbose $templateContentsActualRaw
        Write-Verbose " ***************** END OF ACTUAL CONTENTS ***************"
        Write-Host " `n`n************* EXPECTED CONTENTS ****************"
        Write-Host $templateContentsExpectedRaw
        Write-Host " ***************** END OF EXPECTED CONTENTS ***************"
        Write-Host " `n`n************* DIFFERENCES (IGNORING METADATA) ****************`n"
        $diffs | Out-String | Write-Information Write-Host " `n***************** END OF DIFFERENCES ***************"
    }
    return $false
}
else {
    if($WriteToHost) {
        Write-Host "Files are identical (not counting metadata)"
    }
    return $true
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n