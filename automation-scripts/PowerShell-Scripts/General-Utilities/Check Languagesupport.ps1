#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Check Languagesupport

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
    We Enhanced Check Languagesupport

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

    Detect/validate which languages are supported by inspecting the files that are in the sample folder



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $sampleFolder = $WEENV:SAMPLE_FOLDER,
    $mainTemplateFilenameBicep = $WEENV:MAINTEMPLATE_FILENAME
)

#region Functions

Write-WELog " Checking languages supported by sample: $sampleFolder" " INFO"

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

Write-WELog " Found ${mainTemplateFilenameBicep}: $isBicepFileFound" " INFO"
Write-WELog " Found ${mainTemplateFilenameJson}: $isJsonFileFound" " INFO"



if($isBicepFileFound){
   ;  $mainTemplateDeploymentFilename = $mainTemplateFilenameBicep
}else{
   ;  $mainTemplateDeploymentFilename = $mainTemplateFilenameJson
}

Write-WELog " ##vso[task.setvariable variable=bicep.supported]$isBicepFileFound" " INFO"
Write-WELog " ##vso[task.setvariable variable=mainTemplate.filename.json]$mainTemplateFilenameJson" " INFO"
Write-WELog " ##vso[task.setvariable variable=mainTemplate.deployment.filename]$mainTemplateDeploymentFilename" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
