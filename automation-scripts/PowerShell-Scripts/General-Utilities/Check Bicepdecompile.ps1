<#
.SYNOPSIS
    We Enhanced Check Bicepdecompile

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

    Detect unwanted raw output from bicep decompile command



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    $sampleFolder = $WEENV:SAMPLE_FOLDER
)

Write-WELog "Finding all bicep files in: $sampleFolder" " INFO"
$bicepFiles = Get-ChildItem -Path " $sampleFolder\*.bicep" -Recurse

foreach ($f in $bicepFiles) {

   ;  $bicepText = Get-Content -Path $f.FullName -Raw

    # check for use of _var, _resource, _param - raw output from decompile
    $bicepText | Select-String -Pattern " resource \w{1,}_resource | \w{1,}_var | \w{1,}_param | \s\w{1,}_id\s" -AllMatches |
    foreach-object { $_.Matches } | foreach-object {
        Write-Warning " $($f.Name) may contain raw output from decompile, please clean up: $($_.Value)"
        # write the environment var
        Write-WELog " ##vso[task.setvariable variable=label.decompile.clean-up.needed]$true" " INFO"
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
