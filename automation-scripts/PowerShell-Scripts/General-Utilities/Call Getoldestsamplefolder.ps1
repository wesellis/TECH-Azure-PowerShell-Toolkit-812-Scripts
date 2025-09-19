#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Call Getoldestsamplefolder

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Call Getoldestsamplefolder

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEENV:BUILD_SOURCESDIRECTORY = (Resolve-Path "$WEPSScriptRoot/../.." ).ToString()
$WEENV:SAMPLE_FOLDER = " ."
$WEENV:SAMPLE_NAME = Split-Path -Leaf $WEPSScriptRoot
$WEENV:STORAGE_ACCOUNT_NAME = " azureqsbicep" # TODO
$WEENV:RESULT_BEST_PRACTICE = " FAIL"
$WEENV:RESULT_CREDSCAN = " PASS"
$WEENV:BUILD_REASON = " PullRequest"
$WEENV:AGENT_JOBSTATUS = " Succeeded"
$WEENV:VALIDATION_TYPE = ""
$WEENV:SUPPORTED_ENVIRONMENTS = " ['AzureUSGovernment','AzureCloud']"
$WEENV:RESULT_DEPLOYMENT_PARAMETER = " PublicDeployment"
$WEENV:RESULT_DEPLOYMENT_LAST_TEST_DATE_PARAMETER = " PublicLastTestDate"
$WEENV:RESULT_DEPLOYMENT = " True"
$WEENV:BICEP_VERSION = " 0.3.1"
$WEStorageAccountKey = " $WEENV:STORAGE_ACCOUNT_KEY"
$WEENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER = " 123"
$WEENV:BUILD_BUILDNUMBER = " 1234.56"

if (($WEStorageAccountKey -eq "" ) -or ($null -eq $WEStorageAccountKey)) {
    Write-Error " Missing StorageAccountKey"
}

$params = @{
    PurgeOldRows = $false #TODO REMOVE
    TableName = " QuickStartsMetadataService"
    StorageAccountKey = $WEStorageAccountKey
}
& @params


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
