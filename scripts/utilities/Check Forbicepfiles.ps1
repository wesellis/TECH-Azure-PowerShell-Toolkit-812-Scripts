#Requires -Version 7.4

<#
.SYNOPSIS
    Check for Bicep files and compile them

.DESCRIPTION
    Detects which Bicep files need to be compiled and compiles them automatically.
    This should be run upon merge of a sample to auto-create azuredeploy.json

.PARAMETER SampleFolder
    Path to the sample folder containing Bicep files

.PARAMETER MainTemplateFilenameBicep
    Name of the main Bicep template file

.PARAMETER PrereqTemplateFilenameBicep
    Name of the prerequisite Bicep template file

.PARAMETER PrereqTemplateFileName
    Name of the prerequisite JSON template file

.PARAMETER TtkFolder
    Path to the TTK (Template Toolkit) folder

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
    [string]$MainTemplateFilenameBicep = $ENV:MAINTEMPLATE_FILENAME,

    [Parameter()]
    [string]$PrereqTemplateFilenameBicep = $ENV:PREREQ_TEMPLATE_FILENAME_BICEP,

    [Parameter()]
    [string]$PrereqTemplateFileName = $ENV:PREREQ_TEMPLATE_FILENAME_JSON,

    [Parameter()]
    [string]$TtkFolder = $ENV:TTK_FOLDER
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    if ([string]::IsNullOrWhiteSpace($SampleFolder)) {
        throw "SampleFolder parameter is required"
    }

    Write-Output "Checking for bicep files in: $SampleFolder"

    $BicepFullPath = "$SampleFolder\$MainTemplateFilenameBicep"
    $IsBicepFileFound = Test-Path $BicepFullPath

    $PrereqBicepFullPath = "$SampleFolder\prereqs\$PrereqTemplateFilenameBicep"
    $IsBicepPrereqFileFound = Test-Path $PrereqBicepFullPath

    Write-Output "Bicep files:"
    Write-Output "  Main: $BicepFullPath (Found: $IsBicepFileFound)"
    Write-Output "  Prereq: $PrereqBicepFullPath (Found: $IsBicepPrereqFileFound)"
    Write-Output "************************"

    if ($IsBicepFileFound -or $IsBicepPrereqFileFound) {
        Write-Verbose "Installing Bicep CLI"
        & "$TtkFolder\ci-scripts\Install-Bicep.ps1"

        Write-Verbose "Verifying Bicep installation"
        Get-Command -ErrorAction Stop bicep.exe

        if ($IsBicepFileFound) {
            $outputFile = "$SampleFolder\azuredeploy.json"
            Write-Output "Building: $outputFile"
            bicep build $BicepFullPath --outfile $outputFile
            Write-Verbose "Successfully built main template"
        }

        if ($IsBicepPrereqFileFound) {
            $prereqOutputFile = "$SampleFolder\prereqs\$PrereqTemplateFileName"
            Write-Output "Building: $prereqOutputFile"
            bicep build $PrereqBicepFullPath --outfile $prereqOutputFile
            Write-Verbose "Successfully built prerequisite template"
        }

        Write-Output "Bicep compilation completed successfully"
    } else {
        Write-Output "No Bicep files found to compile"
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}