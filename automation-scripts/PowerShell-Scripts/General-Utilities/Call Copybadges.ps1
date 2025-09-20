<#
.SYNOPSIS
    Call Copybadges

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Import-Module "$PSScriptRoot/../ci-scripts/Local.psm1" -force
$StorageAccountName = " azureqsbicep" # TODO
$StorageAccountKey = " $ENV:STORAGE_ACCOUNT_KEY"
if (($StorageAccountKey -eq "" ) -or ($null -eq $StorageAccountKey)) {
    Write-Error "Missing StorageAccountKey"
    return
}
$ENV:BUILD_REASON = "IndividualCI"
$ENV:BUILD_SOURCEVERSIONMESSAGE = "Add francecentral in azAppInsightsLocationMap (#9498)"
$ENV:BUILD_REPOSITORY_NAME = "Azure/azure-quickstart-templates"
$ENV:BUILD_REPOSITORY_LOCALPATH = Get-SampleRootPath -ErrorAction Stop
$ENV:BUILD_SOURCESDIRECTORY = Get-SampleRootPath -ErrorAction Stop
$getSampleFolderHost
Write-Output $getSampleFolderHost
$vars = Find-VarsFromWriteHostOutput $getSampleFolderHost
$SampleName = $vars["SAMPLE_NAME" ]
$script = " $PSScriptRoot/../ci-scripts/Copy-Badges"
$params = @{
    StorageAccountKey = $StorageAccountKey
    SampleName = $SampleName
    TableNamePRs = "QuickStartsMetadataServicePRs"
    StorageAccountName = $StorageAccountName
    TableName = "QuickStartsMetadataService"
}
& @params\n