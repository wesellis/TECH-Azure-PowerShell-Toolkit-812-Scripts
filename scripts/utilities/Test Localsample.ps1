#Requires -Version 7.4

<#`n.SYNOPSIS
    Test Localsample

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
This script runs some validation on an Azure QuickStarts sample locally so that simple errors can be caught before
a PR is submitted.
Prerequesites:
1)
try {
Install bicep
    - Make sure it's on the path, or set environment variable BICEP_PATH to point to the executable
2) Install the Azure TTK (https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/test-toolkit)
    - Set environment variable TTK_FOLDER to the installation folder location
Usage:
1) cd to the sample folder
2) ../test/test-localsample.bat (Windows)
     or
   ../test/test-localsample.sh (Mac/Linux)
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [string][Parameter(Mandatory = $true)][AllowEmptyString()] $SampleFolder,
    [string] $StorageAccountName = $ENV:STORAGE_ACCOUNT_NAME ? $ENV:STORAGE_ACCOUNT_NAME : " azurequickstartsservice" ,
    [string] $CloudEnvironment = "AzureCloud" , # AzureCloud/AzureUSGovernment
    [string] $TtkFolder = $ENV:TTK_FOLDER,
    [string] $BicepPath = $ENV:BICEP_PATH ? $ENV:BICEP_PATH : " bicep" ,
    [switch] $Fix
)
    $SampleFolder = $SampleFolder -eq "" ? " ." : $SampleFolder
    $PreviousErrorPreference = $ErrorActionPreference
    $Error.Clear()
Import-Module " $PSScriptRoot/Local.psm1" -force
    $ResolvedSampleFolder = Resolve-Path $SampleFolder
if (!$ResolvedSampleFolder) {
    throw "Could not resolve folder $SampleFolder"
}
    $SampleFolder = $ResolvedSampleFolder
    $SampleName = SampleNameFromFolderPath $SampleFolder
if (!(Test-Path (Join-Path $SampleFolder " metadata.json" ))) {
    $ErrorActionPreference = $PreviousErrorPreference
    Write-Error "Test-LocalSample must be run from within a sample folder. This folder contains no metadata.json file."
    return
}
Write-Output "Running local validation on sample $SampleName in folder $SampleFolder"
Write-Output "Checking bicep support in the sample"
    $CheckLanguageHostOutput -MainTemplateFilenameBicep " main.bicep" 6>&1" -SampleFolder $SampleFolder
Write-Output $CheckLanguageHostOutput
    $vars = Find-VarsFromWriteHostOutput $CheckLanguageHostOutput
    $BicepSupported = $vars["BICEP_SUPPORTED" ] -eq 'true'
    $BicepVersion = $vars["BICEP_VERSION" ]
    $MainTemplateFilenameJson = $vars["MAINTEMPLATE_FILENAME_JSON" ]
Assert-NotEmptyOrNull $MainTemplateFilenameJson " mainTemplateFilenameJson"
Write-Output "Validating deployment file"
    $params = @{
    SampleFolder = $SampleFolder
    MainTemplateFilenameJson = $MainTemplateFilenameJson
    BicepVersion = " (current)"
    BicepPath = $BicepPath
    BuildReason = "PullRequest"
    MainTemplateFilenameBicep = " main.bicep"
}
    $BuildHostOutput @params
Write-Output $BuildHostOutput
    $vars = Find-VarsFromWriteHostOutput $BuildHostOutput
    $MainTemplateDeploymentFilename = $vars["MAINTEMPLATE_DEPLOYMENT_FILENAME" ]
Assert-NotEmptyOrNull $MainTemplateDeploymentFilename " mainTemplateDeploymentFilename"
    $CompiledJsonFilename = $vars["COMPILED_JSON_FILENAME" ] # $null if not bicep sample
    $LabelBicepWarnings = $vars["LABEL_BICEP_WARNINGS" ] -eq "TRUE"
Write-Output "Validating metadata.json"
    $MetadataHostOutput =
    $params = @{
    BuildReason = "PullRequest" 6>&1"
    SampleFolder = $SampleFolder
    CloudEnvironment = $CloudEnvironment
}
& @params
Write-Output $MetadataHostOutput
    $vars = Find-VarsFromWriteHostOutput $MetadataHostOutput
    $SupportedEnvironmentsJson = $vars["SUPPORTED_ENVIRONMENTS" ]
Assert-NotEmptyOrNull $SupportedEnvironmentsJson " supportedEnvironmentsJson"
Write-Output "Validating README.md"
    $ValidateReadMeHostOutput =
    $params = @{
    SampleName = $SampleName
    supportedEnvironmentsJson = $SupportedEnvironmentsJson
    StorageAccountName = $StorageAccountName
    SampleFolder = $SampleFolder
    ReadMeFileName = "README.md"
}
& @params
Write-Output $ValidateReadMeHostOutput
    $vars = Find-VarsFromWriteHostOutput $ValidateReadMeHostOutput
    $ResultReadMe = $vars["RESULT_README" ] # will be null if fails
    $FixedReadme = $vars["FIXED_README" ] -eq "TRUE"
if (!$TtkFolder) {
    $TtkFolder = " $PSScriptRoot/../../../arm-ttk"
    if (test-path $TtkFolder) {
    $TtkFolder = Resolve-Path $TtkFolder
    }
    else {
    $ErrorActionPreference = $PreviousErrorPreference
        Write-Error "Could not find the ARM TTK. Please install from https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/test-toolkit and set environment variable TTK_FOLDER to the installation folder location."
        Return
    }
}
Write-Output "Validating JSON best practices (using ARM TTK)"
    $ValidateBPOutput =
    $params = @{
    ttkFolder = $TtkFolder 6>&1
    SampleFolder = $SampleFolder
    MainTemplateDeploymentFilename = $MainTemplateDeploymentFilename
}
& @params
Write-Output $ValidateBPOutput
    $vars = Find-VarsFromWriteHostOutput $ValidateBPOutput
Write-Output "Checking for miscellaneous labels"
    $MiscLabelsHostOutput =
& -SampleName $SampleName 6>&1
Write-Output $MiscLabelsHostOutput
    $vars = Find-VarsFromWriteHostOutput $MiscLabelsHostOutput
    $IsRootSample = $vars["ISROOTSAMPLE" ] -eq " true"
    $SampleHasUpperCase = $vars["SampleHasUpperCase" ] -eq " true"
    $IsPortalSample = $vars["IsPortalSample" ] -eq " true"
if ($null -ne $CompiledJsonFilename -and (Test-Path $CompiledJsonFilename)) {
    Remove-Item -ErrorAction Stop $CompiledJsonFilenam -Forcee -Force
}
Write-Output "Validation complete."
    $FixesMade = $FixedReadme
if ($FixedReadme) {
    Write-Warning "A fix has been made in the README. See details above."
}
if ($error) {
    Write-Error " *** ERRORS HAVE BEEN FOUND. SEE DETAILS ABOVE ***"
}
else {
    if (!$FixesMade) {
        Write-Output "No errors found."
    }
}
if ($LabelBicepWarnings) {
    Write-Warning "LABEL: bicep warnings"
}
if ($IsRootSample) {
    Write-Warning "LABEL: ROOT"
}
if ($SampleHasUpperCase) {
    Write-Warning "LABEL: UPPERCASE"
}
if ($IsPortalSample) {
    Write-Warning "LABEL: PORTAL SAMPLE"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
