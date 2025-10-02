#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Storage, AzTable

<#
.SYNOPSIS
    Copy Badges

.DESCRIPTION
    Azure automation script used to copy badges from the "prs" container to the "badges" container.
    The badges are created in the "prs" container when the pipeline test is executed on the PR,
    but we don't want to copy those results until approved. When the PR is merged, the CI pipeline
    copies the badges to the "badges" folder to reflect the live/current results.

.PARAMETER SampleName
    Name of the sample (can be provided via environment variable SAMPLE_NAME)

.PARAMETER StorageAccountName
    Name of the Azure Storage Account (can be provided via environment variable STORAGE_ACCOUNT_NAME)

.PARAMETER TableName
    Name of the metadata table for live results (default: QuickStartsMetadataService)

.PARAMETER TableNamePRs
    Name of the metadata table for PR results (default: QuickStartsMetadataServicePRs)

.PARAMETER StorageAccountKey
    Access key for the Azure Storage Account

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SampleName = $ENV:SAMPLE_NAME,

    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = $ENV:STORAGE_ACCOUNT_NAME,

    [Parameter(Mandatory=$false)]
    [string]$TableName = "QuickStartsMetadataService",

    [Parameter(Mandatory=$false)]
    [string]$TableNamePRs = "QuickStartsMetadataServicePRs",

    [Parameter(Mandatory=$true)]
    [string]$StorageAccountKey
)

$ErrorActionPreference = "Stop"

try {
    # Validate required parameters
    if ([string]::IsNullOrWhiteSpace($SampleName)) {
        Write-Error "SampleName is empty. Please provide it via parameter or SAMPLE_NAME environment variable."
        throw
    }
    else {
        Write-Output "SampleName: $SampleName"
    }

    if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
        Write-Error "StorageAccountName is empty. Please provide it via parameter or STORAGE_ACCOUNT_NAME environment variable."
        throw
    }
    else {
        Write-Output "StorageAccountName: $StorageAccountName"
    }

    # Clean up the storage folder name for Azure Storage compatibility
    $StorageFolder = $SampleName.Replace("\", "@").Replace("/", "@")
    $RowKey = $StorageFolder
    Write-Output "RowKey: $RowKey"

    # Create storage context
    $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment AzureCloud

    # Get cloud tables
    $CloudTable = (Get-AzStorageTable -Name $TableName -Context $StorageContext).CloudTable
    $CloudTablePRs = (Get-AzStorageTable -Name $TableNamePRs -Context $StorageContext).CloudTable

    # Copy blobs from "prs" to "badges" container
    Write-Output "Copying badges from 'prs' to 'badges' container..."
    $BlobPrefix = $StorageFolder.Replace("@", "/")
    $Blobs = Get-AzStorageBlob -Context $StorageContext -Container "prs" -Prefix $BlobPrefix

    if ($Blobs) {
        Write-Output "Found $($Blobs.Count) blobs to copy"
        $Blobs | Start-AzStorageBlobCopy -DestContainer "badges" -Verbose -Force
        $Blobs | Remove-AzStorageBlob -Verbose -Force
        Write-Output "Badges copied and removed from prs container"
    }
    else {
        Write-Warning "No blobs found with prefix: $BlobPrefix"
    }

    # Update table records
    Write-Output "Fetching row for: $RowKey in Table: $TableNamePRs"
    $TableRow = Get-AzTableRow -Table $CloudTablePRs -ColumnName "RowKey" -Value $RowKey -Operator Equal

    if ($null -eq $TableRow) {
        Write-Error "Could not find row with key $RowKey in table $TableNamePRs"
        throw
    }

    Write-Output "Result from Table: $TableRow"

    # Update status to "Live"
    if ($null -eq $TableRow.status) {
        Write-Output "Adding status column..."
        Add-Member -InputObject $TableRow -NotePropertyName "status" -NotePropertyValue "Live"
    }
    else {
        $TableRow.status = "Live"
    }

    Write-Output "Updating LIVE table with..."
    $TableRow | Format-List *

    # Prepare properties for the live table
    $Properties = @{}
    foreach ($Property in $TableRow.PSObject.Properties) {
        if ($Property.Name -ne "Etag") {
            $NewValue = switch ($Property.Value) {
                "true"  { "PASS" }
                "false" { "FAIL" }
                default { $Property.Value }
            }
            $Properties.Add($Property.Name, $NewValue)
        }
    }

    Write-Output "New properties..."
    $Properties | Out-String

    # Add/Update row in live table
    Write-Output "Add/Update Row in live table..."
    $TableParams = @{
        Table = $CloudTable
        Property = $Properties
        PartitionKey = $TableRow.PartitionKey
        RowKey = $TableRow.RowKey
    }
    Add-AzTableRow @TableParams

    # Remove row from PR table
    Write-Output "Removing row from PR table..."
    $TableRow | Remove-AzTableRow -Table $CloudTablePRs

    Write-Output "Badge copy operation completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}