<#
.SYNOPSIS
    Check Prereqs

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    This script will check to see if there are prereqs and set the flag to deploy them
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()]
    $sampleFolder = $ENV:SAMPLE_FOLDER,
    [Parameter()]
    $prereqTemplateFilenameBicep = $ENV:PREREQ_TEMPLATE_FILENAME_BICEP,
    [Parameter()]
    $prereqTemplateFilenameJson = $ENV:PREREQ_TEMPLATE_FILENAME_JSON
)
$deployPrereqs = Test-Path " $sampleFolder\prereqs\"
Write-Host " ##vso[task.setvariable variable=deploy.prereqs]$deployPrereqs"
$bicepPrereqTemplateFullPath = " $sampleFolder\prereqs\$prereqTemplateFilenameBicep"
$jsonPrereqTemplateFullPath = " $sampleFolder\prereqs\$prereqTemplateFilenameJson"
Write-Host "Checking for bicep: $bicepPrereqTemplateFullPath"
Write-Host "Checking for JSON: $jsonPrereqTemplateFullPath"
if(Test-Path -Path $bicepPrereqTemplateFullPath){
    Write-Host "Using bicep..."
$prereqTemplateFullPath = $bicepPrereqTemplateFullPath
}else{
    Write-Host "Using JSON..."
$prereqTemplateFullPath = $jsonPrereqTemplateFullPath
}
Write-Output "Using prereq template: $prereqTemplateFullPath"
if ($deployPrereqs) {
    Write-Host " ##vso[task.setvariable variable=prereq.template.fullpath]$prereqTemplateFullPath"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

