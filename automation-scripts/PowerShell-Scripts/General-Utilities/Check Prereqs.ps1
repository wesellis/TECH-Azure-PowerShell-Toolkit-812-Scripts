<#
.SYNOPSIS
    We Enhanced Check Prereqs

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

    This script will check to see if there are prereqs and set the flag to deploy them



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    $sampleFolder = $WEENV:SAMPLE_FOLDER,
    $prereqTemplateFilenameBicep = $WEENV:PREREQ_TEMPLATE_FILENAME_BICEP,
    $prereqTemplateFilenameJson = $WEENV:PREREQ_TEMPLATE_FILENAME_JSON
)


$deployPrereqs = Test-Path "$sampleFolder\prereqs\"
Write-WELog " ##vso[task.setvariable variable=deploy.prereqs]$deployPrereqs" " INFO"


$bicepPrereqTemplateFullPath = " $sampleFolder\prereqs\$prereqTemplateFilenameBicep"
$jsonPrereqTemplateFullPath = " $sampleFolder\prereqs\$prereqTemplateFilenameJson"

Write-WELog " Checking for bicep: $bicepPrereqTemplateFullPath" " INFO"
Write-WELog " Checking for JSON: $jsonPrereqTemplateFullPath" " INFO"


if(Test-Path -Path $bicepPrereqTemplateFullPath){
    Write-WELog " Using bicep..." " INFO"
    $prereqTemplateFullPath = $bicepPrereqTemplateFullPath
}else{
    Write-WELog " Using JSON..." " INFO"
   ;  $prereqTemplateFullPath = $jsonPrereqTemplateFullPath
}

Write-Output " Using prereq template: $prereqTemplateFullPath"
if ($deployPrereqs) {
    Write-WELog " ##vso[task.setvariable variable=prereq.template.fullpath]$prereqTemplateFullPath" " INFO"
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
