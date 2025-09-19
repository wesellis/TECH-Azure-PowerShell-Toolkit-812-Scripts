#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Check Forbicepfiles

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Check Forbicepfiles

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

    Detect which bicep files need to be compiled and compile them - this should be run upon merge of a sample to auto-create azuredeploy.json



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $sampleFolder = $WEENV:SAMPLE_FOLDER,
    $mainTemplateFilenameBicep = $WEENV:MAINTEMPLATE_FILENAME,
    $prereqTemplateFilenameBicep = $WEENV:PREREQ_TEMPLATE_FILENAME_BICEP,
    $prereqTemplateFileName = $WEENV:PREREQ_TEMPLATE_FILENAME_JSON,
    $ttkFolder = $WEENV:TTK_FOLDER
)

#region Functions



Write-WELog " Checking for bicep files in: $sampleFolder" " INFO"

$bicepFullPath = " $sampleFolder\$mainTemplateFilenameBicep"
$isBicepFileFound = Test-Path $bicepFullPath
; 
$prereqBicepFullPath = " $sampleFolder\prereqs\$prereqTemplateFilenameBicep" ; 
$isBicepPrereqFileFound = Test-Path $prereqBicepFullPath

Write-Output " Bicep files:"
Write-Information $bicepFullPath
Write-Information $prereqBicepFullPath
Write-Output " ************************"

if($isBicepFileFound -or $isBicepPrereqFileFound){
    # Install Bicep
    & " $ttKFolder\ci-scripts\Install-Bicep.ps1"

    Get-Command -ErrorAction Stop bicep.exe

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


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
