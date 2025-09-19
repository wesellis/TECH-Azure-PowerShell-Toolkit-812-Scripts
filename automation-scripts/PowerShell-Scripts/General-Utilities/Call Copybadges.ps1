#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Call Copybadges

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
    We Enhanced Call Copybadges

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Import-Module "$WEPSScriptRoot/../ci-scripts/Local.psm1" -force

$WEStorageAccountName = " azureqsbicep" # TODO
$WEStorageAccountKey = " $WEENV:STORAGE_ACCOUNT_KEY"

if (($WEStorageAccountKey -eq "" ) -or ($null -eq $WEStorageAccountKey)) {
    Write-Error " Missing StorageAccountKey"
    return
}

$WEENV:BUILD_REASON = " IndividualCI"
$WEENV:BUILD_SOURCEVERSIONMESSAGE = " Add francecentral in azAppInsightsLocationMap (#9498)"
$WEENV:BUILD_REPOSITORY_NAME = " Azure/azure-quickstart-templates"
$WEENV:BUILD_REPOSITORY_LOCALPATH = Get-SampleRootPath -ErrorAction Stop
$WEENV:BUILD_SOURCESDIRECTORY = Get-SampleRootPath -ErrorAction Stop

$getSampleFolderHost 
Write-Output $getSampleFolderHost
$vars = Find-VarsFromWriteHostOutput $getSampleFolderHost
; 
$WESampleName = $vars[" SAMPLE_NAME" ]
; 
$script = " $WEPSScriptRoot/../ci-scripts/Copy-Badges"
$params = @{
    StorageAccountKey = $WEStorageAccountKey
    SampleName = $WESampleName
    TableNamePRs = " QuickStartsMetadataServicePRs"
    StorageAccountName = $WEStorageAccountName
    TableName = " QuickStartsMetadataService"
}
& @params


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
