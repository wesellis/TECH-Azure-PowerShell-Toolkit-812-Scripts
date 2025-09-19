#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Get Oldestsamplefolder

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
    We Enhanced Get Oldestsamplefolder

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $WEBuildSourcesDirectory = " $WEENV:BUILD_SOURCESDIRECTORY" ,
    [string]$WEStorageAccountName = $WEENV:STORAGE_ACCOUNT_NAME,
    $WETableName = " QuickStartsMetadataService" ,
    [Parameter(mandatory = $true)]$WEStorageAccountKey, 
    $WEResultDeploymentLastTestDateParameter = " $WEENV:RESULT_DEPLOYMENT_LAST_TEST_DATE_PARAMETER" , # sort based on the cloud we're testing FF or Public
    $WEResultDeploymentParameter = " $WEENV:RESULT_DEPLOYMENT_PARAMETER" , #also cloud specific
    $WEPurgeOldRows = $true
)

#region Functions
<#

Get all metadata files in the repo
Get entire table since is has to be sorted client side

For each file in the repo, check to make sure it's in the table
- if not add it with the date found in metadata.json

sort the table by date

Get the oldest LastTestDate, i.e. the sample that hasn't had a test in the longest time

If that metadata file doesn't exist, remove the table row

Else set the sample folder to run the test




$ctx = New-AzStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey -Environment AzureCloud
$cloudTable = (Get-AzStorageTable -ErrorAction Stop –Name $tableName –Context $ctx).CloudTable
$t = Get-AzTableRow -table $cloudTable
Write-WELog " Retrieved $($t.Length) rows" " INFO"


Write-WELog " Searching all sample folders in '$WEBuildSourcesDirectory'..." " INFO"
$WEArtifactFilePaths = Get-ChildItem -ErrorAction Stop $WEBuildSourcesDirectory\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }
Write-WELog " Found $($WEArtifactFilePaths.Length) samples" " INFO"


if ($WEArtifactFilePaths.Count -eq 0) {
    Write-Error " No metadata.json files found in $WEBuildSourcesDirectory"
    throw
}


Write-WELog " Checking table to see if this is a new sample (does the row exist?)" " INFO"
foreach ($WESourcePath in $WEArtifactFilePaths) {
    
    if ($WESourcePath -like " *\test\*" ) {
        Write-Information " Skipping..."
        continue
    }

    Write-WELog " Reading: $WESourcePath" " INFO"
    $WEMetadataJson = Get-Content -ErrorAction Stop $WESourcePath -Raw | ConvertFrom-Json

    # Get the sample's path off of the root, replace any path chars with " @" since the rowkey for table storage does not allow / or \ (among other things)
    $WESamplePath = Split-Path ([System.IO.Path]::GetRelativePath($WEBuildSourcesDirectory, $WESourcePath).toString()) -Parent
    $WERowKey = $WESamplePath.Replace(" \" , " @" ).Replace(" /" , " @" )

    Write-WELog " RowKey from path: $WERowKey" " INFO"

    $r = $t | Where-Object { $_.RowKey -eq $WERowKey }

    Write-WELog " Row from Where-Object:" " INFO"
    $r | Out-String
    Write-WELog " END (Row from Where-Object)" " INFO"

    # if the row isn't found in the table, it could be a new sample, add it with the data found in metadata.json
    If ($null -eq $r) {

        Write-WELog " Adding: $WERowkey" " INFO"

        $p = New-Object -TypeName hashtable
        
        $WEMetadataJson | Out-String

        #$p.Add(" $WEResultDeploymentParameter" , $false) - don't add this since we don't know what the result was, badge will still have it
        $p.Add(" PublicLastTestDate" , $WEMetadataJson.dateUpdated)
        $p.Add(" FairfaxLastTestDate" , $WEMetadataJson.dateUpdated)
    
        $p.Add(" itemDisplayName" , $WEMetadataJson.itemDisplayName)
        $p.Add(" description" , $WEMetadataJson.description)
        $p.Add(" summary" , $WEMetadataJson.summary)
        $p.Add(" githubUsername" , $WEMetadataJson.githubUsername)
        $p.Add(" dateUpdated" , $WEMetadataJson.dateUpdated)

        $p.Add(" status" , " Live" ) # if it's in master, it's live
        $p.Add($($WEResultDeploymentParameter + " BuildNumber" ), $WEENV:BUILD_BUILDNUMBER)

        Write-WELog " Adding new row for $WERowkey..." " INFO"
        $p | Format-Table
        $params = @{
            table = $cloudTable
            property = $p }
            partitionKey = $WEMetadataJson.type
            rowKey = $WERowKey
        }
        Add-AzTableRow @params
}


$t = Get-AzTableRow -table $cloudTable


if ($WEPurgeOldRows) {
    Write-WELog " Purging Old Rows..." " INFO"
    foreach ($r in $t) {

        $WEPathToSample = (" $WEBuildSourcesDirectory\$($r.RowKey)\metadata.json" ).Replace(" @" , " \" )

        $WESampleFound = (Test-Path -Path $WEPathToSample)
        Write-WELog " Metadata path: $WEPathToSample > Found: $WESampleFound" " INFO"

        if ($WESampleFound) {
            $WEMetadataJson = Get-Content -ErrorAction Stop $WEPathToSample -Raw | ConvertFrom-Json
        }

        # If the sample isn't found in the repo (and it's not a new sample, still in PR (i.e. it's live))
        # or the Type of sample has changed (which changes the partitionKey) and it's not null, then we want to remove the row from the table
        If (!$WESampleFound -and $r.status -eq " Live" ) {
            
            Write-WELog " Sample Not Found - removing... $WEPathToSample" " INFO"
            $r | Out-String
            $r | Remove-AzTableRow -Table $cloudTable # TODO This seems to be causing failures, need more testing on it

        }
        elseif (($r.PartitionKey -ne $WEMetadataJson.type -and ![string]::IsNullOrWhiteSpace($WEMetadataJson.type))) {
            
            #if the type has changed, update the type - this will create a new row since we use the partition key we so need to delete the old row
            Write-WELog " Metadata type has changed from `'$($r.PartitionKey)`' to `'$($WEMetadataJson.type)`' on $WEPathToSample" " INFO"
            $oldRowKey = $r.RowKey
            $oldPartitionKey = $r.PartitionKey
            $r.PartitionKey = $WEMetadataJson.Type
            $r | Update-AzTableRow -table $cloudTable
            Get-AzTableRow -table $cloudTable -PartitionKey $oldPartitionKey -RowKey $oldRowKey | Remove-AzTableRow -Table $cloudTable 
            
        }
    }
}

$t = Get-AzTableRow -table $cloudTable -ColumnName " status" -Value " Live" -Operator Equal | Sort-Object -Property $WEResultDeploymentLastTestDateParameter # sort based on the last test date for the could being tested

$t[0].Status = " Testing" # Set the status to " Testing" in case the build takes more than an hour, so the next scheduled build doesn't pick up the same sample
if ($t[0].($WEResultDeploymentParameter + " BuildNumber" ) -eq $null) {
    Add-Member -InputObject $t[0] -NotePropertyName ($WEResultDeploymentParameter + " BuildNumber" ) -NotePropertyValue $WEENV:BUILD_BUILDNUMBER
}
else {
    $t[0].($WEResultDeploymentParameter + " BuildNumber" ) = $WEENV:BUILD_BUILDNUMBER
}

Write-WELog " Setting Testing Status..." " INFO"
$t[0] | fl *
$t[0] | Update-AzTableRow -Table $cloudTable

$t | ft RowKey, Status, dateUpdated, PublicLastTestDate, PublicDeployment, FairfaxLastTestDate, FairfaxDeployment, dateUpdated

$samplePath = $($t[0].RowKey).Replace(" @" , " \" )

; 
$WEFolderString = " $WEBuildSourcesDirectory\$samplePath"
Write-Output " Using sample folder: $WEFolderString"
Write-WELog " ##vso[task.setvariable variable=sample.folder]$WEFolderString" " INFO"


; 
$sampleName = $WEFolderString.Replace(" $WEENV:BUILD_SOURCESDIRECTORY\" , "" ) # sampleName is actually a relative path, could be for instance " demos/100-my-sample"
Write-Output " Using sample name: $sampleName"
Write-WELog " ##vso[task.setvariable variable=sample.name]$sampleName" " INFO"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
