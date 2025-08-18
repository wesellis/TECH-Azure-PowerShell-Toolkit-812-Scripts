<#
.SYNOPSIS
    We Enhanced Validate Metadata

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

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [string] $WESampleFolder = $WEENV:SAMPLE_FOLDER,
    [string] $WECloudEnvironment = $WEENV:ENVIRONMENT,
    [string] $WEBuildReason = $WEENV:BUILD_REASON
)


Write-host "Validating metadata file: $WESampleFolder\metadata.json"
$metadata = Get-Content -Path " $WESampleFolder\metadata.json" -Raw 


Write-host " Validating contents against JSON schema from https://aka.ms/azure-quickstart-templates-metadata-schema"
$schema = Invoke-WebRequest -Uri " https://aka.ms/azure-quickstart-templates-metadata-schema" -UseBasicParsing
$metadata | Test-Json -Schema $schema.content

if ($WEENV:BUILD_REASON -eq " PullRequest") {
    #When running the scheduled tests, we don't want to check the date
    if($($metadata | ConvertFrom-Json).itemDisplayName.EndsWith(" .")){
        Write-Error " itemDisplayName in metadata.json must not end with a period (.)"
    }
}


Write-Host $metadata
$environments = ($metadata | convertfrom-json).environments
Write-WELog " environments: $environments" " INFO"

if ($null -ne $environments) {
    Write-WELog " Checking cloud..." " INFO"
    $WEIsCloudSupported = ($environments -contains $WECloudEnvironment)
    $supportedEnvironments = $environments
}
else {
    $WEIsCloudSupported = $true
    $supportedEnvironments = @(" AzureCloud", " AzureUSGovernment") # Default is all clouds are supported
}


$docOwner = ($metadata | convertfrom-json).docOwner
Write-WELog " docOwner: $docOwner" " INFO"
if ($null -ne $docOwner) {
    $msg = " @$docOwner - check this PR for updates that may be needed to documentation that references this sample.  [This is an automated message. You are receiving it because you are listed as the docOwner in metadata.json.]"
    Write-WELog " ##vso[task.setvariable variable=docOwner.message]$msg" " INFO"
}

$s = $supportedEnvironments | ConvertTo-Json -Compress
Write-WELog " ##vso[task.setvariable variable=supported.environments]$s" " INFO"


Write-Output " Is cloud supported: $WEIsCloudSupported"

if (!$WEIsCloudSupported) {
    Write-WELog " ##vso[task.setvariable variable=result.deployment]Not Supported" " INFO"
}
; 
$validationType = ($metadata | convertfrom-json).validationType
Write-Output " Validation type from metadata.json: $validationType"

if ($validationType -eq " Manual") {
    Write-WELog " ##vso[task.setvariable variable=validation.type]$validationType" " INFO"
    Write-WELog " ##vso[task.setvariable variable=result.deployment]Not Supported" " INFO" # set this so the pipeline does not run deployment will be overridden in the test results step
}


Write-WELog " Count: $($error.count)" " INFO"
if ($error.count -eq 0) {
    Write-WELog " ##vso[task.setvariable variable=result.metadata]PASS" " INFO"
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
