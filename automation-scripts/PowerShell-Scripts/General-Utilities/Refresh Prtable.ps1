#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Refresh Prtable

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
    We Enhanced Refresh Prtable

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $WEGitHubRepository = " $WEENV:BUILD_REPOSITORY_NAME" ,
    $WEBuildSourcesDirectory = " $WEENV:BUILD_SOURCESDIRECTORY" ,
    $WETableName = " QuickStartsMetadataServicePRs" ,
    [string]$WEStorageAccountResourceGroupName = " azure-quickstarts-template-hash" ,
    [string]$WEStorageAccountName = " azurequickstartsservice" ,
    [Parameter(mandatory = $true)]$WEStorageAccountKey,
    [string]$basicAuthCreds # if needed to run manually add creds in the format of " user:token"
)

#region Functions

<#

Get all rows in the PR table
See if the PRs in GH have been closed, if so remove the row from the PR table



$ctx = New-AzStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey " $WEStorageAccountKey" -Environment AzureCloud
$cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable
$rows = Get-AzTableRow -table $cloudTable

foreach($r in $rows){

    $WEPRUri = " https://api.github.com/repos/$($WEGitHubRepository)/pulls/$($r.pr)"

    $response = ""
    if($basicAuthCreds){
       ;  $response = curl -u $basicAuthCreds " $WEPRUri" | ConvertFrom-Json
    } else {
       ;  $response = curl " $WEPRUri" | ConvertFrom-Json
    }

    Write-WELog " PR# $($r.pr) is $($response.state)..." " INFO"

    if($response.state -eq 'closed'){
        Write-WELog " Removing... $($r.RowKey)" " INFO"
        $r | Remove-AzTableRow -Table $cloudTable
    }

}


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
