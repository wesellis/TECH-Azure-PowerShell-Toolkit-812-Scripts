<#
.SYNOPSIS
    We Enhanced Compare Templates

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

﻿
<# 

Verifies that two JSON template files have the same hash (after removing generator metadata)
try {
    # Main script execution
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string][Parameter(mandatory = $true)] $WETemplateFilePathExpected,
    [string][Parameter(mandatory = $true)] $WETemplateFilePathActual,
    [switch] $WERemoveGeneratorMetadata,
    [switch] $WEWriteToHost
)

Import-Module "$WEPSScriptRoot/Local.psm1" -Force

if ($WEWriteToHost) {
    Write-WELog " Comparing $WETemplateFilePathExpected and $WETemplateFilePathActual" " INFO"
}

$templateContentsExpectedRaw = Get-Content $WETemplateFilePathExpected -Raw
$templateContentsActualRaw = Get-Content $WETemplateFilePathActual -Raw

if ($WERemoveGeneratorMetadata) {
    $templateContentsExpectedRaw = Remove-GeneratorMetadata $templateContentsExpectedRaw
    $templateContentsActualRaw = Remove-GeneratorMetadata $templateContentsActualRaw
}

$templateContentsExpected = Convert-StringToLines $templateContentsExpectedRaw
$templateContentsActual = Convert-StringToLines $templateContentsActualRaw


; 
$diffs = Compare-Object $templateContentsExpected $templateContentsActual

if ($diffs) {
    if ($WEWriteToHost) {
        Write-Warning " The templates do not match"
        Write-Verbose " `n`n************* ACTUAL CONTENTS ****************"
        Write-Verbose $templateContentsActualRaw
        Write-Verbose " ***************** END OF ACTUAL CONTENTS ***************"
        Write-WELog " `n`n************* EXPECTED CONTENTS ****************" " INFO"
        Write-Host $templateContentsExpectedRaw
        Write-host " ***************** END OF EXPECTED CONTENTS ***************"

        Write-WELog " `n`n************* DIFFERENCES (IGNORING METADATA) ****************`n" " INFO"
        $diffs | Out-String | Write-Host
        Write-WELog " `n***************** END OF DIFFERENCES ***************" " INFO"
    }
    
    return $false
}
else {
    if($WEWriteToHost) {
        Write-WELog " Files are identical (not counting metadata)" " INFO"
    }
    return $true
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
