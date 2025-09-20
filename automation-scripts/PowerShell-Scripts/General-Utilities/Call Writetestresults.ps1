<#
.SYNOPSIS
    Call Writetestresults

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ENV:SAMPLE_FOLDER = "."
$ENV:SAMPLE_NAME = Split-Path (Resolve-Path $ENV:SAMPLE_FOLDER) -Leaf
$ENV:STORAGE_ACCOUNT_NAME = " azureqsbicep" # TODO
$ENV:RESULT_BEST_PRACTICE = "FAIL"
$ENV:RESULT_CREDSCAN = "PASS"
$ENV:BUILD_REASON = "BatchedCI" # PullRequest/BatchedCI/IndividualCI/Manual
$ENV:AGENT_JOBSTATUS = "Succeeded"
$ENV:VALIDATION_TYPE = ""
$ENV:SUPPORTED_ENVIRONMENTS = " ['AzureUSGovernment','AzureCloud']"
$ENV:RESULT_DEPLOYMENT_PARAMETER = "PublicDeployment"
$ENV:RESULT_DEPLOYMENT = "True"
$ENV:BICEP_VERSION = " 0.3.1"
$StorageAccountKey = " $ENV:STORAGE_ACCOUNT_KEY"
$ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER = " 123"
$ENV:BUILD_BUILDNUMBER = " 1234.56"
if (($StorageAccountKey -eq "" ) -or ($null -eq $StorageAccountKey)) {
    Write-Error "Missing StorageAccountKey"
    return
}
$script = " $PSScriptRoot/../ci-scripts/Write-TestResults"
$params = @{
    PublicDeployment = $ENV:RESULT_DEPLOYMENT
    PRsContainerName = " badgestest"
    BadgesContainerName = " badgestest"
    TableName = "QuickStartsMetadataServiceTest"
    TableNamePRs = "QuickStartsMetadataServiceTestPRs"
    StorageAccountKey = $StorageAccountKey
}
& @params

