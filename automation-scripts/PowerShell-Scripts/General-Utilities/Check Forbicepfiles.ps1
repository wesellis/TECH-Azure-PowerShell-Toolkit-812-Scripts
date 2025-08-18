<#
.SYNOPSIS
    We Enhanced Check Forbicepfiles

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

    Detect which bicep files need to be compiled and compile them - this should be run upon merge of a sample to auto-create azuredeploy.json



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    $sampleFolder = $WEENV:SAMPLE_FOLDER,
    $mainTemplateFilenameBicep = $WEENV:MAINTEMPLATE_FILENAME,
    $prereqTemplateFilenameBicep = $WEENV:PREREQ_TEMPLATE_FILENAME_BICEP,
    $prereqTemplateFileName = $WEENV:PREREQ_TEMPLATE_FILENAME_JSON,
    $ttkFolder = $WEENV:TTK_FOLDER
)



Write-WELog "Checking for bicep files in: $sampleFolder" " INFO"

$bicepFullPath = " $sampleFolder\$mainTemplateFilenameBicep"
$isBicepFileFound = Test-Path $bicepFullPath

$prereqBicepFullPath = " $sampleFolder\prereqs\$prereqTemplateFilenameBicep"; 
$isBicepPrereqFileFound = Test-Path $prereqBicepFullPath

Write-Output " Bicep files:"
Write-Host $bicepFullPath
Write-Host $prereqBicepFullPath
Write-Output " ************************"

if($isBicepFileFound -or $isBicepPrereqFileFound){
    # Install Bicep
    & " $ttKFolder\ci-scripts\Install-Bicep.ps1"

    Get-Command bicep.exe

    if($isBicepFileFound){
        # build main.bicep to azuredeploy.json
        Write-Output " Building: $sampleFolder\azuredeploy.json"
        bicep build $bicepFullPath --outfile " $sampleFolder\azuredeploy.json"
    }

    if($isBicepPrereqFileFound){
        # build prereq.main.bicep to prereq.azuredeploy.json
        Write-Output " Building: $sampleFolder\prereqs\$prereqTemplateFileName"
        bicep build $prereqBicepFullPath --outfile " $sampleFolder\prereqs\$prereqTemplateFileName"
    }
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
