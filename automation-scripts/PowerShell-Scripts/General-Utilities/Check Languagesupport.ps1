<#
.SYNOPSIS
    Check Languagesupport

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Detect/validate which languages are supported by inspecting the files that are in the sample folder
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $sampleFolder = $ENV:SAMPLE_FOLDER,
    $mainTemplateFilenameBicep = $ENV:MAINTEMPLATE_FILENAME
)
Write-Host "Checking languages supported by sample: $sampleFolder"
$bicepFullPath = " $sampleFolder\$mainTemplateFilenameBicep"
$isBicepFileFound = Test-Path $bicepFullPath
$jsonFilename1 = " azuredeploy.json"
$jsonFilename2 = " mainTemplate.json"
$isJsonFileFound = Test-Path " $($sampleFolder)\$jsonFilename1"
if ($isJsonFileFound) {
    $mainTemplateFilenameJson = $jsonFilename1
}
else {
    $isJsonFileFound = Test-Path " $($sampleFolder)\$jsonFilename2"
    if ($isJsonFileFound) {
        $mainTemplateFilenameJson = $jsonFilename2
    }
    else {
        # Neither is found.  Use azudeploy.json in error messages
        $mainTemplateFilenameJson = $jsonFilename1
    }
}
Write-Host "Found ${mainTemplateFilenameBicep}: $isBicepFileFound"
Write-Host "Found ${mainTemplateFilenameJson}: $isJsonFileFound"
if($isBicepFileFound){
$mainTemplateDeploymentFilename = $mainTemplateFilenameBicep
}else{
$mainTemplateDeploymentFilename = $mainTemplateFilenameJson
}
Write-Host " ##vso[task.setvariable variable=bicep.supported]$isBicepFileFound"
Write-Host " ##vso[task.setvariable variable=mainTemplate.filename.json]$mainTemplateFilenameJson"
Write-Host " ##vso[task.setvariable variable=mainTemplate.deployment.filename]$mainTemplateDeploymentFilename"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

