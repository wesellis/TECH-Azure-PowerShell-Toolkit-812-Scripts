<#
.SYNOPSIS
    We Enhanced Refresh Prtable

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
    $WEGitHubRepository = "$WEENV:BUILD_REPOSITORY_NAME" ,
    $WEBuildSourcesDirectory = "$WEENV:BUILD_SOURCESDIRECTORY" ,
    $WETableName = "QuickStartsMetadataServicePRs" ,
    [string]$WEStorageAccountResourceGroupName = "azure-quickstarts-template-hash" ,
    [string]$WEStorageAccountName = "azurequickstartsservice" ,
    [Parameter(mandatory = $true)]$WEStorageAccountKey,
    [string]$basicAuthCreds # if needed to run manually add creds in the format of "user:token"
)

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
        $response = curl -u $basicAuthCreds " $WEPRUri" | ConvertFrom-Json
    } else {
       ;  $response = curl " $WEPRUri" | ConvertFrom-Json
    }

    Write-WELog " PR# $($r.pr) is $($response.state)..." " INFO"

    if($response.state -eq 'closed'){
        Write-WELog " Removing... $($r.RowKey)" " INFO"
        $r | Remove-AzTableRow -Table $cloudTable
    }

}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
