#Requires -Version 7.4

<#
.SYNOPSIS
    Check Language Support

.DESCRIPTION
    Detects and validates which languages are supported by inspecting the files
    that are in the sample folder (Bicep vs JSON templates)

.PARAMETER SampleFolder
    Path to the sample folder to check

.PARAMETER MainTemplateFilenameBicep
    Name of the main Bicep template file

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleFolder = $ENV:SAMPLE_FOLDER,

    [Parameter()]
    [string]$MainTemplateFilenameBicep = $ENV:MAINTEMPLATE_FILENAME
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    if ([string]::IsNullOrWhiteSpace($SampleFolder)) {
        throw "SampleFolder parameter is required"
    }

    Write-Output "Checking languages supported by sample: $SampleFolder"

    $BicepFullPath = "$SampleFolder\$MainTemplateFilenameBicep"
    $IsBicepFileFound = Test-Path $BicepFullPath

    $JsonFilename1 = "azuredeploy.json"
    $JsonFilename2 = "mainTemplate.json"

    $IsJsonFileFound = Test-Path "$SampleFolder\$JsonFilename1"

    if ($IsJsonFileFound) {
        $MainTemplateFilenameJson = $JsonFilename1
        Write-Verbose "Found primary JSON template: $JsonFilename1"
    } else {
        $IsJsonFileFound = Test-Path "$SampleFolder\$JsonFilename2"
        if ($IsJsonFileFound) {
            $MainTemplateFilenameJson = $JsonFilename2
            Write-Verbose "Found secondary JSON template: $JsonFilename2"
        } else {
            $MainTemplateFilenameJson = $JsonFilename1
            Write-Verbose "No JSON template found, defaulting to: $JsonFilename1"
        }
    }

    Write-Output "Found $MainTemplateFilenameBicep: $IsBicepFileFound"
    Write-Output "Found $MainTemplateFilenameJson: $IsJsonFileFound"

    if ($IsBicepFileFound) {
        $MainTemplateDeploymentFilename = $MainTemplateFilenameBicep
        Write-Verbose "Using Bicep template for deployment"
    } else {
        $MainTemplateDeploymentFilename = $MainTemplateFilenameJson
        Write-Verbose "Using JSON template for deployment"
    }

    Write-Output "##vso[task.setvariable variable=bicep.supported]$IsBicepFileFound"
    Write-Output "##vso[task.setvariable variable=mainTemplate.filename.json]$MainTemplateFilenameJson"
    Write-Output "##vso[task.setvariable variable=mainTemplate.deployment.filename]$MainTemplateDeploymentFilename"

    Write-Verbose "Language support check completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}