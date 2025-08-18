<#
.SYNOPSIS
    Test Localsample

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
.SYNOPSIS
    We Enhanced Test Localsample

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

This script runs some validation on an Azure QuickStarts sample locally so that simple errors can be caught before
a PR is submitted.

Prerequesites:

1)
try {
    # Main script execution
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
    [string][Parameter(Mandatory = $true)][AllowEmptyString()] $WESampleFolder, # this is the path to the sample
    [string] $WEStorageAccountName = $WEENV:STORAGE_ACCOUNT_NAME ? $WEENV:STORAGE_ACCOUNT_NAME : " azurequickstartsservice" ,
    [string] $WECloudEnvironment = " AzureCloud" , # AzureCloud/AzureUSGovernment
    [string] $WETtkFolder = $WEENV:TTK_FOLDER,
    [string] $WEBicepPath = $WEENV:BICEP_PATH ? $WEENV:BICEP_PATH : " bicep" ,
    [switch] $WEFix # If true, fixes will be made if possible
)

$WESampleFolder = $WESampleFolder -eq "" ? " ." : $WESampleFolder

$WEPreviousErrorPreference = $WEErrorActionPreference
$WEErrorActionPreference = " Continue"
$WEError.Clear()

Import-Module " $WEPSScriptRoot/Local.psm1" -force

$WEResolvedSampleFolder = Resolve-Path $WESampleFolder
if (!$WEResolvedSampleFolder) {
    throw " Could not resolve folder $WESampleFolder"
}
$WESampleFolder = $WEResolvedSampleFolder

$WESampleName = SampleNameFromFolderPath $WESampleFolder

if (!(Test-Path (Join-Path $WESampleFolder " metadata.json" ))) {
    $WEErrorActionPreference = $WEPreviousErrorPreference
    Write-Error " Test-LocalSample must be run from within a sample folder. This folder contains no metadata.json file."
    return
}

Write-WELog " Running local validation on sample $WESampleName in folder $WESampleFolder" " INFO"


Write-WELog " Checking bicep support in the sample" " INFO"
$checkLanguageHostOutput = & $WEPSScriptRoot/Check-LanguageSupport.ps1 `
    -SampleFolder $WESampleFolder `
    -MainTemplateFilenameBicep " main.bicep" `
    6>&1
Write-Output $checkLanguageHostOutput
$vars = Find-VarsFromWriteHostOutput $checkLanguageHostOutput
$bicepSupported = $vars[" BICEP_SUPPORTED" ] -eq 'true'
$bicepVersion = $vars[" BICEP_VERSION" ]
$mainTemplateFilenameJson = $vars[" MAINTEMPLATE_FILENAME_JSON" ]
Assert-NotEmptyOrNull $mainTemplateFilenameJson " mainTemplateFilenameJson"


Write-Information " Validating deployment file"

$buildHostOutput = & $WEPSScriptRoot/Validate-DeploymentFile.ps1 `
    -SampleFolder $WESampleFolder `
    -MainTemplateFilenameBicep " main.bicep" `
    -MainTemplateFilenameJson $mainTemplateFilenameJson `
    -BuildReason " PullRequest" `
    -BicepPath $WEBicepPath `
    -BicepVersion " (current)" `
    -BicepSupported:$bicepSupported `
    6>&1
Write-Output $buildHostOutput
$vars = Find-VarsFromWriteHostOutput $buildHostOutput
$mainTemplateDeploymentFilename = $vars[" MAINTEMPLATE_DEPLOYMENT_FILENAME" ]
Assert-NotEmptyOrNull $mainTemplateDeploymentFilename " mainTemplateDeploymentFilename"
$WECompiledJsonFilename = $vars[" COMPILED_JSON_FILENAME" ] # $null if not bicep sample
$labelBicepWarnings = $vars[" LABEL_BICEP_WARNINGS" ] -eq " TRUE"


Write-WELog " Validating metadata.json" " INFO"
$metadataHostOutput =
& $WEPSScriptRoot/Validate-Metadata.ps1 `
    -SampleFolder $WESampleFolder `
    -CloudEnvironment $WECloudEnvironment `
    -BuildReason " PullRequest" `
    6>&1
Write-Output $metadataHostOutput
$vars = Find-VarsFromWriteHostOutput $metadataHostOutput
$supportedEnvironmentsJson = $vars[" SUPPORTED_ENVIRONMENTS" ]
Assert-NotEmptyOrNull $supportedEnvironmentsJson " supportedEnvironmentsJson"


Write-WELog " Validating README.md" " INFO"
$validateReadMeHostOutput =
& $WEPSScriptRoot/Validate-ReadMe.ps1 `
    -SampleFolder $WESampleFolder `
    -SampleName $WESampleName `
    -StorageAccountName $WEStorageAccountName `
    -ReadMeFileName " README.md" `
    -supportedEnvironmentsJson $supportedEnvironmentsJson `
    -bicepSupported:$bicepSupported `
    -Fix:$WEFix `
    6>&1
Write-Output $validateReadMeHostOutput
$vars = Find-VarsFromWriteHostOutput $validateReadMeHostOutput
$resultReadMe = $vars[" RESULT_README" ] # will be null if fails
$fixedReadme = $vars[" FIXED_README" ] -eq " TRUE"


if (!$WETtkFolder) {
    # Check if the TTK is in a local repo as a sibling to this repo
    $WETtkFolder = " $WEPSScriptRoot/../../../arm-ttk"
    if (test-path $WETtkFolder) {
        $WETtkFolder = Resolve-Path $WETtkFolder
    }
    else {
        $WEErrorActionPreference = $WEPreviousErrorPreference
        Write-Error " Could not find the ARM TTK. Please install from https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/test-toolkit and set environment variable TTK_FOLDER to the installation folder location."
        Return
    }
}
Write-WELog " Validating JSON best practices (using ARM TTK)" " INFO"
$validateBPOutput =
& $WEPSScriptRoot/Test-BestPractices.ps1 `
    -SampleFolder $WESampleFolder `
    -MainTemplateDeploymentFilename $mainTemplateDeploymentFilename `
    -ttkFolder $WETtkFolder `
    6>&1
Write-Output $validateBPOutput
$vars = Find-VarsFromWriteHostOutput $validateBPOutput


Write-WELog " Checking for miscellaneous labels" " INFO"
$miscLabelsHostOutput =
& $WEPSScriptRoot/Check-MiscLabels.ps1 `
    -SampleName $WESampleName `
    6>&1
Write-Output $miscLabelsHostOutput
$vars = Find-VarsFromWriteHostOutput $miscLabelsHostOutput
$isRootSample = $vars[" ISROOTSAMPLE" ] -eq " true"
$sampleHasUpperCase = $vars[" SampleHasUpperCase" ] -eq " true"
$isPortalSample = $vars[" IsPortalSample" ] -eq " true"


if ($null -ne $WECompiledJsonFilename -and (Test-Path $WECompiledJsonFilename)) {
    Remove-Item -ErrorAction Stop $WECompiledJsonFilenam -Forcee -Force
}

Write-Information " Validation complete."
; 
$fixesMade = $fixedReadme
if ($fixedReadme) {
    Write-Warning " A fix has been made in the README. See details above."
}

if ($error) {
   ;  $WEErrorActionPreference = $WEPreviousErrorPreference
    Write-Error " *** ERRORS HAVE BEEN FOUND. SEE DETAILS ABOVE ***"
}
else {
    if (!$fixesMade) {
        Write-WELog " No errors found." " INFO"
    }
}

if ($labelBicepWarnings) {
    Write-Warning " LABEL: bicep warnings"
}
if ($isRootSample) {
    Write-Warning " LABEL: ROOT"
}
if ($sampleHasUpperCase) {
    Write-Warning " LABEL: UPPERCASE"
}
if ($isPortalSample) {
    Write-Warning " LABEL: PORTAL SAMPLE"
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
