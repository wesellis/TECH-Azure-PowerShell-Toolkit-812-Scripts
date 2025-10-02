#Requires -Version 7.4

<#
.SYNOPSIS
    Check Prerequisites

.DESCRIPTION
    This script checks to see if there are prerequisites and sets the flag to deploy them.
    It also determines which template format to use (Bicep or JSON).

.PARAMETER SampleFolder
    Path to the sample folder to check

.PARAMETER PrereqTemplateFilenameBicep
    Name of the prerequisite Bicep template file

.PARAMETER PrereqTemplateFilenameJson
    Name of the prerequisite JSON template file

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
    [string]$PrereqTemplateFilenameBicep = $ENV:PREREQ_TEMPLATE_FILENAME_BICEP,

    [Parameter()]
    [string]$PrereqTemplateFilenameJson = $ENV:PREREQ_TEMPLATE_FILENAME_JSON
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    if ([string]::IsNullOrWhiteSpace($SampleFolder)) {
        throw "SampleFolder parameter is required"
    }

    Write-Verbose "Checking for prerequisites in: $SampleFolder"

    $DeployPrereqs = Test-Path "$SampleFolder\prereqs\"
    Write-Output "##vso[task.setvariable variable=deploy.prereqs]$DeployPrereqs"

    if ($DeployPrereqs) {
        $BicepPrereqTemplateFullPath = "$SampleFolder\prereqs\$PrereqTemplateFilenameBicep"
        $JsonPrereqTemplateFullPath = "$SampleFolder\prereqs\$PrereqTemplateFilenameJson"

        Write-Output "Checking for bicep: $BicepPrereqTemplateFullPath"
        Write-Output "Checking for JSON: $JsonPrereqTemplateFullPath"

        if (Test-Path -Path $BicepPrereqTemplateFullPath) {
            Write-Output "Using bicep template..."
            $PrereqTemplateFullPath = $BicepPrereqTemplateFullPath
            Write-Verbose "Bicep prerequisite template found"
        } else {
            Write-Output "Using JSON template..."
            $PrereqTemplateFullPath = $JsonPrereqTemplateFullPath
            Write-Verbose "Using JSON prerequisite template"
        }

        Write-Output "Using prereq template: $PrereqTemplateFullPath"
        Write-Output "##vso[task.setvariable variable=prereq.template.fullpath]$PrereqTemplateFullPath"
    } else {
        Write-Output "No prerequisites folder found"
        Write-Verbose "Prerequisites not required for this sample"
    }

    Write-Verbose "Prerequisites check completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}