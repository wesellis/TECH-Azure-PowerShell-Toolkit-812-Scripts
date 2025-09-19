#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Copy Badges

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
    We Enhanced Copy Badges

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

This script is used to copy the badges from the "prs" container to the " badges" container.  
The badges are created in the " prs" container when the pipleline test is executed on the PR, but we don't want to copy those results until approved
Then, when the PR is merged, the CI pipeline copies the badges to the " badges" folder to reflect the live/current results



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = " Stop"
[CmdletBinding()]
param(
    [string]$WESampleName = $WEENV:SAMPLE_NAME, # the name of the sample or folder path from the root of the repo e.g. " sample-type/sample-name"
    [string]$WEStorageAccountName = $WEENV:STORAGE_ACCOUNT_NAME,
    [string]$WETableName = " QuickStartsMetadataService" ,
    [string]$WETableNamePRs = " QuickStartsMetadataServicePRs" ,
    [Parameter(mandatory = $true)]$WEStorageAccountKey
)

#region Functions

if ([string]::IsNullOrWhiteSpace($WESampleName)) {
    Write-Error " SampleName is empty"
}
else {
    Write-WELog " SampleName: $WESampleName" " INFO"
}

$storageFolder = $WESampleName.Replace(" \" , " @" ).Replace(" /" , " @" )
$WERowKey = $storageFolder
Write-WELog " RowKey: $WERowKey" " INFO"


$ctx = New-AzStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey -Environment AzureCloud
$cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable
$cloudTablePRs = (Get-AzStorageTable -Name $tableNamePRs -Context $ctx).CloudTable


$blobs = Get-AzStorageBlob -Context $ctx -Container " prs" -Prefix $storageFolder.Replace(" @" , " /" ) 
$blobs | Start-AzStorageBlobCopy -DestContainer " badges" -Verbose -Force
$blobs | Remove-AzStorageBlob -Verbose -Force


Write-WELog " Fetching row for: $WERowKey in Table: $cloudTablePRs" " INFO"
$r = Get-AzTableRow -table $cloudTablePRs -ColumnName " RowKey" -Value $WERowKey -Operator Equal
if ($null -eq $r) {
    Write-Error " Could not find row with key $WERowKey in table $cloudTablePRs"
    Return
}
Write-WELog " Result from Table: $r" " INFO"


if ($null -eq $r.status) {
    Write-WELog " Adding status column..." " INFO"
    Add-Member -InputObject $r -NotePropertyName " status" -NotePropertyValue " Live"
}
else {
    $r.status = " Live"
}

Write-WELog " Updating LIVE table with..." " INFO"
$r | Format-List *

$p = @{ }
foreach ($i in $r.PSObject.Properties) {
    if ($i.Name -ne " Etag" ) {
        if ($i.value -eq " true" ) {
            $newValue = " PASS"
        }
        elseif ($i.value -eq " false" ) {
           ;  $newValue = " FAIL"
        }
        else { 
           ;  $newValue = $i.Value
        }
        $p.Add($i.Name, $newValue)
    }
}

Write-WELog " New properties..." " INFO"
$p | out-string


Write-WELog " Add/Update Row in live table..." " INFO"
$params = @{
    table = $cloudTable
    property = $p
    partitionKey = $r.partitionKey
    rowKey = $r.rowKey
}
Add-AzTableRow @params
Write-WELog " Removing row from PR table..." " INFO"
$r | Remove-AzTableRow -Table $cloudTablePRs




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
