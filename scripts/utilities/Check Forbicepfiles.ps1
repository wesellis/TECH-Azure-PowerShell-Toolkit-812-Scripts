#Requires -Version 7.0

<#`n.SYNOPSIS
    Check Forbicepfiles

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Detect which bicep files need to be compiled and compile them - this should be run upon merge of a sample to auto-create azuredeploy.json
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
    $mainTemplateFilenameBicep = $ENV:MAINTEMPLATE_FILENAME,
    [Parameter()]
    $prereqTemplateFilenameBicep = $ENV:PREREQ_TEMPLATE_FILENAME_BICEP,
    [Parameter()]
    $prereqTemplateFileName = $ENV:PREREQ_TEMPLATE_FILENAME_JSON,
    [Parameter()]
    $ttkFolder = $ENV:TTK_FOLDER
)
Write-Host "Checking for bicep files in: $sampleFolder"
$bicepFullPath = " $sampleFolder\$mainTemplateFilenameBicep"
$isBicepFileFound = Test-Path $bicepFullPath
$prereqBicepFullPath = " $sampleFolder\prereqs\$prereqTemplateFilenameBicep" ;
$isBicepPrereqFileFound = Test-Path $prereqBicepFullPath
Write-Output "Bicep files:"
Write-Host $bicepFullPath
Write-Host $prereqBicepFullPath
Write-Output " ************************"
if($isBicepFileFound -or $isBicepPrereqFileFound){
    # Install Bicep
    & " $ttKFolder\ci-scripts\Install-Bicep.ps1"
    Get-Command -ErrorAction Stop bicep.exe
    if($isBicepFileFound){
        # build main.bicep to azuredeploy.json
        Write-Output "Building: $sampleFolder\azuredeploy.json"
        bicep build $bicepFullPath --outfile " $sampleFolder\azuredeploy.json"
    }
    if($isBicepPrereqFileFound){
        # build prereq.main.bicep to prereq.azuredeploy.json
        Write-Output "Building: $sampleFolder\prereqs\$prereqTemplateFileName"
        bicep build $prereqBicepFullPath --outfile " $sampleFolder\prereqs\$prereqTemplateFileName"
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


