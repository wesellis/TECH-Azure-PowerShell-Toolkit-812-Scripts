#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get Oldestsamplefolder

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules

.PARAMETER BuildSourcesDirectory
    Build sources directory path

.PARAMETER StorageAccountName
    Storage account name

.PARAMETER TableName
    Table name for metadata service

.PARAMETER StorageAccountKey
    Storage account key (mandatory)

.PARAMETER ResultDeploymentLastTestDateParameter
    Result deployment last test date parameter

.PARAMETER ResultDeploymentParameter
    Result deployment parameter

.PARAMETER PurgeOldRows
    Whether to purge old rows
#>

[CmdletBinding()]
param(
    $BuildSourcesDirectory = $ENV:BUILD_SOURCESDIRECTORY,
    $StorageAccountName = $ENV:STORAGE_ACCOUNT_NAME,
    $TableName = "QuickStartsMetadataService",
    [Parameter(Mandatory = $true)]$StorageAccountKey,
    $ResultDeploymentLastTestDateParameter = $ENV:RESULT_DEPLOYMENT_LAST_TEST_DATE_PARAMETER, # sort based on the cloud we're testing FF or Public
    $ResultDeploymentParameter = $ENV:RESULT_DEPLOYMENT_PARAMETER, #also cloud specific
    $PurgeOldRows = $true
)

$ErrorActionPreference = "Stop"

try {
    # Get all metadata files in the repo
    # Get entire table since is has to be sorted client side
    # For each file in the repo, check to make sure it's in the table
    # - if not add it with the date found in metadata.json
    # sort the table by date
    # Get the oldest LastTestDate, i.e. the sample that hasn't had a test in the longest time
    # If that metadata file doesn't exist, remove the table row
    # Else set the sample folder to run the test
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment AzureCloud
    $CloudTable = (Get-AzStorageTable -ErrorAction Stop -Name $TableName -Context $ctx).CloudTable
    $t = Get-AzTableRow -table $CloudTable
    Write-Output "Retrieved $($t.Length) rows"
    Write-Output "Searching all sample folders in '$BuildSourcesDirectory'..."
    $ArtifactFilePaths = Get-ChildItem -ErrorAction Stop "$BuildSourcesDirectory\metadata.json" -Recurse -File | ForEach-Object -Process { $_.FullName }
    Write-Output "Found $($ArtifactFilePaths.Length) samples"
    if ($ArtifactFilePaths.Count -eq 0) {
        Write-Error "No metadata.json files found in $BuildSourcesDirectory"
        throw
    }
    Write-Output "Checking table to see if this is a new sample (does the row exist?)"
    foreach ($SourcePath in $ArtifactFilePaths) {
        if ($SourcePath -like "*\test\*") {
            Write-Output "Skipping..."
            continue
        }
        Write-Output "Reading: $SourcePath"
        $MetadataJson = Get-Content -ErrorAction Stop $SourcePath -Raw | ConvertFrom-Json
        $SamplePath = Split-Path ([System.IO.Path]::GetRelativePath($BuildSourcesDirectory, $SourcePath).toString()) -Parent
        $RowKey = $SamplePath.Replace("\", "@").Replace("/", "@")
        Write-Output "RowKey from path: $RowKey"
        $r = $t | Where-Object { $_.RowKey -eq $RowKey }
        Write-Output "Row from Where-Object:"
        $r | Out-String
        Write-Output "END (Row from Where-Object)"
        If ($null -eq $r) {
            Write-Output "Adding: $Rowkey"
            $p = New-Object -TypeName hashtable
            $MetadataJson | Out-String
            $p.Add("PublicLastTestDate", $MetadataJson.dateUpdated)
            $p.Add("FairfaxLastTestDate", $MetadataJson.dateUpdated)
            $p.Add("itemDisplayName", $MetadataJson.itemDisplayName)
            $p.Add("description", $MetadataJson.description)
            $p.Add("summary", $MetadataJson.summary)
            $p.Add("githubUsername", $MetadataJson.githubUsername)
            $p.Add("dateUpdated", $MetadataJson.dateUpdated)
            $p.Add("status", "Live") # if it's in master, it's live
            $p.Add($($ResultDeploymentParameter + "BuildNumber"), $ENV:BUILD_BUILDNUMBER)
            Write-Output "Adding new row for $Rowkey..."
            $p | Format-Table
            $params = @{
                table = $CloudTable
                property = $p
                partitionKey = $MetadataJson.type
                rowKey = $RowKey
            }
            Add-AzTableRow @params
        }
    }
    $t = Get-AzTableRow -table $CloudTable
    if ($PurgeOldRows) {
        Write-Output "Purging Old Rows..."
        foreach ($r in $t) {
            $PathToSample = ("$BuildSourcesDirectory\$($r.RowKey)\metadata.json").Replace("@", "\")
            $SampleFound = (Test-Path -Path $PathToSample)
            Write-Output "Metadata path: $PathToSample > Found: $SampleFound"
            if ($SampleFound) {
                $MetadataJson = Get-Content -ErrorAction Stop $PathToSample -Raw | ConvertFrom-Json
            }
            If (!$SampleFound -and $r.status -eq "Live") {
                Write-Output "Sample Not Found - removing... $PathToSample"
                $r | Out-String
                $r | Remove-AzTableRow -Table $CloudTable
            }
            elseif (($r.PartitionKey -ne $MetadataJson.type -and ![string]::IsNullOrWhiteSpace($MetadataJson.type))) {
                Write-Output "Metadata type has changed from '$($r.PartitionKey)' to '$($MetadataJson.type)' on $PathToSample"
                $OldRowKey = $r.RowKey
                $OldPartitionKey = $r.PartitionKey
                $r.PartitionKey = $MetadataJson.Type
                $r | Update-AzTableRow -table $CloudTable
                Get-AzTableRow -table $CloudTable -PartitionKey $OldPartitionKey -RowKey $OldRowKey | Remove-AzTableRow -Table $CloudTable
            }
        }
    }
    $t = Get-AzTableRow -table $CloudTable -ColumnName "status" -Value "Live" -Operator Equal | Sort-Object -Property $ResultDeploymentLastTestDateParameter # sort based on the last test date for the could being tested
    $t[0].Status = "Testing"
    if ($t[0].($ResultDeploymentParameter + "BuildNumber") -eq $null) {
        Add-Member -InputObject $t[0] -NotePropertyName ($ResultDeploymentParameter + "BuildNumber") -NotePropertyValue $ENV:BUILD_BUILDNUMBER
    }
    else {
        $t[0].($ResultDeploymentParameter + "BuildNumber") = $ENV:BUILD_BUILDNUMBER
    }
    Write-Output "Setting Testing Status..."
    $t[0] | fl *
    $t[0] | Update-AzTableRow -Table $CloudTable
    $t | ft RowKey, Status, dateUpdated, PublicLastTestDate, PublicDeployment, FairfaxLastTestDate, FairfaxDeployment, dateUpdated
    $SamplePath = $($t[0].RowKey).Replace("@", "\")
    $FolderString = "$BuildSourcesDirectory\$SamplePath"
    Write-Output "Using sample folder: $FolderString"
    Write-Output "##vso[task.setvariable variable=sample.folder]$FolderString"
    $SampleName = $FolderString.Replace("$ENV:BUILD_SOURCESDIRECTORY\", "") # sampleName is actually a relative path, could be for instance "demos/100-my-sample"
    Write-Output "Using sample name: $SampleName"
    Write-Output "##vso[task.setvariable variable=sample.name]$SampleName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
