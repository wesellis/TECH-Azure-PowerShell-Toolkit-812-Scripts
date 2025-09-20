#Requires -Version 7.0

<#`n.SYNOPSIS
    Validate Metadata

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $CloudEnvironment = $ENV:ENVIRONMENT,
    [string] $BuildReason = $ENV:BUILD_REASON
)
Write-Host "Validating metadata file: $SampleFolder\metadata.json"
$metadata = Get-Content -Path " $SampleFolder\metadata.json" -Raw
Write-Host "Validating contents against JSON schema from https://aka.ms/azure-quickstart-templates-metadata-schema"
$schema = Invoke-WebRequest -Uri " https://aka.ms/azure-quickstart-templates-metadata-schema" -UseBasicParsing
$metadata | Test-Json -Schema $schema.content
if ($ENV:BUILD_REASON -eq "PullRequest" ) {
    #When running the scheduled tests, we don't want to check the date
    if($($metadata | ConvertFrom-Json).itemDisplayName.EndsWith(" ." )){
        Write-Error " itemDisplayName in metadata.json must not end with a period (.)"
    }
}
Write-Host $metadata
$environments = ($metadata | convertfrom-json).environments
Write-Host " environments: $environments"
if ($null -ne $environments) {
    Write-Host "Checking cloud..."
    $IsCloudSupported = ($environments -contains $CloudEnvironment)
    $supportedEnvironments = $environments
}
else {
    $IsCloudSupported = $true
    $supportedEnvironments = @("AzureCloud" , "AzureUSGovernment" ) # Default is all clouds are supported
}
$docOwner = ($metadata | convertfrom-json).docOwner
Write-Host " docOwner: $docOwner"
if ($null -ne $docOwner) {
    $msg = " @docOwner - check this PR for updates that may be needed to documentation that references this sample.  [This is an automated message. You are receiving it because you are listed as the docOwner in metadata.json.]"
    Write-Host " ##vso[task.setvariable variable=docOwner.message]$msg"
}
$s = $supportedEnvironments | ConvertTo-Json -Compress
Write-Host " ##vso[task.setvariable variable=supported.environments]$s"
Write-Output "Is cloud supported: $IsCloudSupported"
if (!$IsCloudSupported) {
    Write-Host " ##vso[task.setvariable variable=result.deployment]Not Supported"
}
$validationType = ($metadata | convertfrom-json).validationType
Write-Output "Validation type from metadata.json: $validationType"
if ($validationType -eq "Manual" ) {
    Write-Host " ##vso[task.setvariable variable=validation.type]$validationType"
    Write-Host " ##vso[task.setvariable variable=result.deployment]Not Supported" # set this so the pipeline does not run deployment will be overridden in the test results step
}
Write-Host "Count: $($error.count)"
if ($error.count -eq 0) {
    Write-Host " ##vso[task.setvariable variable=result.metadata]PASS"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
