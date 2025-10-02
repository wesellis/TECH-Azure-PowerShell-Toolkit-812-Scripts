#Requires -Version 7.4

<#`n.SYNOPSIS
    Call Getoldestsamplefolder

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ENV:BUILD_SOURCESDIRECTORY = (Resolve-Path "$PSScriptRoot/../.." ).ToString()
$ENV:SAMPLE_FOLDER = " ."
$ENV:SAMPLE_NAME = Split-Path -Leaf $PSScriptRoot
$ENV:STORAGE_ACCOUNT_NAME = " azureqsbicep" $ENV:RESULT_BEST_PRACTICE = "FAIL"
$ENV:RESULT_CREDSCAN = "PASS"
$ENV:BUILD_REASON = "PullRequest"
$ENV:AGENT_JOBSTATUS = "Succeeded"
$ENV:VALIDATION_TYPE = ""
$ENV:SUPPORTED_ENVIRONMENTS = " ['AzureUSGovernment','AzureCloud']"
$ENV:RESULT_DEPLOYMENT_PARAMETER = "PublicDeployment"
$ENV:RESULT_DEPLOYMENT_LAST_TEST_DATE_PARAMETER = "PublicLastTestDate"
$ENV:RESULT_DEPLOYMENT = "True"
$ENV:BICEP_VERSION = " 0.3.1"
$StorageAccountKey = " $ENV:STORAGE_ACCOUNT_KEY"
$ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER = " 123"
$ENV:BUILD_BUILDNUMBER = " 1234.56"
if (($StorageAccountKey -eq "" ) -or ($null -eq $StorageAccountKey)) {
    Write-Error "Missing StorageAccountKey"
}
$params = @{
    PurgeOldRows = $false
    TableName = "QuickStartsMetadataService"
    StorageAccountKey = $StorageAccountKey
}
& @params



