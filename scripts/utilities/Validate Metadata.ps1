#Requires -Version 7.4

<#`n.SYNOPSIS
    Validate Metadata

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $CloudEnvironment = $ENV:ENVIRONMENT,
    [string] $BuildReason = $ENV:BUILD_REASON
)
Write-Output "Validating metadata file: $SampleFolder\metadata.json"
    $metadata = Get-Content -Path " $SampleFolder\metadata.json" -Raw
Write-Output "Validating contents against JSON schema from https://aka.ms/azure-quickstart-templates-metadata-schema"
    $schema = Invoke-WebRequest -Uri " https://aka.ms/azure-quickstart-templates-metadata-schema" -UseBasicParsing
    $metadata | Test-Json -Schema $schema.content
if ($ENV:BUILD_REASON -eq "PullRequest" ) {
    if($($metadata | ConvertFrom-Json).itemDisplayName.EndsWith(" ." )){
        Write-Error " itemDisplayName in metadata.json must not end with a period (.)"
    }
}
Write-Output $metadata
    $environments = ($metadata | convertfrom-json).environments
Write-Output " environments: $environments"
if ($null -ne $environments) {
    Write-Output "Checking cloud..."
    $IsCloudSupported = ($environments -contains $CloudEnvironment)
    $SupportedEnvironments = $environments
}
else {
    $IsCloudSupported = $true
    $SupportedEnvironments = @("AzureCloud" , "AzureUSGovernment" ) # Default is all clouds are supported
}
    $DocOwner = ($metadata | convertfrom-json).docOwner
Write-Output " docOwner: $DocOwner"
if ($null -ne $DocOwner) {
    $msg = " @docOwner - check this PR for updates that may be needed to documentation that references this sample.  [This is an automated message. You are receiving it because you are listed as the docOwner in metadata.json.]"
    Write-Output " ##vso[task.setvariable variable=docOwner.message]$msg"
}
$s = $SupportedEnvironments | ConvertTo-Json -Compress
Write-Output " ##vso[task.setvariable variable=supported.environments]$s"
Write-Output "Is cloud supported: $IsCloudSupported"
if (!$IsCloudSupported) {
    Write-Output " ##vso[task.setvariable variable=result.deployment]Not Supported"
}
    $ValidationType = ($metadata | convertfrom-json).validationType
Write-Output "Validation type from metadata.json: $ValidationType"
if ($ValidationType -eq "Manual" ) {
    Write-Output " ##vso[task.setvariable variable=validation.type]$ValidationType"
    Write-Output " ##vso[task.setvariable variable=result.deployment]Not Supported" }
Write-Output "Count: $($error.count)"
if ($error.count -eq 0) {
    Write-Output " ##vso[task.setvariable variable=result.metadata]PASS"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
