#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Storage

<#
.SYNOPSIS
    Refresh Azure Quickstarts Table

.DESCRIPTION
    Azure automation script to refresh the Quickstarts metadata service table.
    Updates the table with metadata from repository and badge status information.

.PARAMETER BuildSourcesDirectory
    Absolute path to the repository clone (defaults to BUILD_SOURCESDIRECTORY environment variable)

.PARAMETER StorageAccountName
    Storage account name (defaults to STORAGE_ACCOUNT_NAME environment variable)

.PARAMETER TableName
    Azure Table Storage table name (default: "QuickStartsMetadataService")

.PARAMETER StorageAccountKey
    Storage account access key (mandatory)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate Azure Storage permissions
    Updates metadata and test status badges for Quickstart templates
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$BuildSourcesDirectory = $ENV:BUILD_SOURCESDIRECTORY,

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = $ENV:STORAGE_ACCOUNT_NAME,

    [Parameter(Mandatory = $false)]
    [string]$TableName = "QuickStartsMetadataService",

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountKey
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Refreshing Quickstarts table"
    Write-Output "Build Sources Directory: $BuildSourcesDirectory"
    Write-Output "Storage Account: $StorageAccountName"
    Write-Output "Table Name: $TableName"

    # Normalize the directory path
    while ($BuildSourcesDirectory.EndsWith("/")) {
        $BuildSourcesDirectory = $BuildSourcesDirectory.TrimEnd("/")
    }
    while ($BuildSourcesDirectory.EndsWith("\")) {
        $BuildSourcesDirectory = $BuildSourcesDirectory.TrimEnd("\")
    }

    # Define badge URLs
    $badges = @{
        PublicLastTestDate  = "https://$StorageAccountName.blob.core.windows.net/badges/%sample.folder%/PublicLastTestDate.svg"
        PublicDeployment    = "https://$StorageAccountName.blob.core.windows.net/badges/%sample.folder%/PublicDeployment.svg"
        FairfaxLastTestDate = "https://$StorageAccountName.blob.core.windows.net/badges/%sample.folder%/FairfaxLastTestDate.svg"
        FairfaxDeployment   = "https://$StorageAccountName.blob.core.windows.net/badges/%sample.folder%/FairfaxDeployment.svg"
        BestPracticeResult  = "https://$StorageAccountName.blob.core.windows.net/badges/%sample.folder%/BestPracticeResult.svg"
        CredScanResult      = "https://$StorageAccountName.blob.core.windows.net/badges/%sample.folder%/CredScanResult.svg"
        BicepVersion        = "https://$StorageAccountName.blob.core.windows.net/badges/%sample.folder%/BicepVersion.svg"
    }

    # Get all metadata files in the repo
    Write-Output "Searching for metadata.json files..."
    $ArtifactFilePaths = Get-ChildItem -Path "$BuildSourcesDirectory\metadata.json" -Recurse -File | ForEach-Object { $_.FullName }

    if ($ArtifactFilePaths.Count -eq 0) {
        throw "No metadata.json files found in $BuildSourcesDirectory"
    }

    Write-Output "Found $($ArtifactFilePaths.Count) metadata.json files"

    # Create storage context
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment AzureCloud

    # Get cloud table reference
    $CloudTable = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable

    if (-not $CloudTable) {
        throw "Unable to get cloud table: $TableName"
    }

    # Process each metadata file
    $processedCount = 0
    foreach ($SourcePath in $ArtifactFilePaths) {
        # Skip test directories
        if ($SourcePath -like "*\test\*") {
            Write-Output "Skipping test directory: $SourcePath"
            continue
        }

        Write-Output "Processing: $SourcePath"

        # Read metadata
        $MetadataJson = Get-Content -Path $SourcePath -Raw | ConvertFrom-Json

        # Generate row key from path
        $RelativePath = (Split-Path $SourcePath -Parent).Replace("$(Resolve-Path $BuildSourcesDirectory)\", "").Replace("\", "@").Replace("/", "@")
        $RowKey = $RelativePath
        Write-Output "RowKey: $RowKey"

        # Get existing row if it exists
        $existingRow = Get-AzTableRow -Table $CloudTable -ColumnName "RowKey" -Value $RowKey -Operator Equal

        # Prepare properties hashtable
        $properties = @{
            itemDisplayName = $MetadataJson.itemDisplayName
            description     = $MetadataJson.description
            summary         = $MetadataJson.summary
            githubUsername  = $MetadataJson.githubUsername
            dateUpdated     = $MetadataJson.dateUpdated
            status          = "Live"  # If it's in master, it's live
        }

        # Process badges
        foreach ($badge in $badges.GetEnumerator()) {
            $uri = $badge.Value.Replace("%sample.folder%", $RowKey.Replace("@", "/"))

            try {
                $svg = Invoke-WebRequest -Uri $uri -ErrorAction SilentlyContinue

                if ($svg) {
                    $xml = $svg.Content.Replace('xmlns="http://www.w3.org/2000/svg"', '')
                    $textNodes = Select-XML -Content $xml -XPath "//text"
                    $value = $textNodes[$textNodes.Length - 1].ToString()

                    # Normalize badge values
                    switch ($value) {
                        "PASS" { $value = "PASS" }
                        "FAIL" { $value = "FAIL" }
                        "Not Supported" { $value = "Not Supported" }
                        "Not Tested" { $value = "Not Tested" }
                        "Bicep Version" { $value = "n/a" }
                        default { }
                    }

                    # Format date values
                    if ($badge.Key -like "*Date") {
                        $value = $value.Replace(".", "-")
                    }

                    if ($null -ne $value) {
                        $properties.Add($badge.Key, $value)
                        Write-Output "  $($badge.Key) = $value"
                    }
                }
            }
            catch {
                Write-Warning "Failed to get badge $($badge.Key): $_"
            }
        }

        # Set default values if not present
        if ([string]::IsNullOrWhiteSpace($properties.FairfaxLastTestDate)) {
            $properties.Add("FairfaxLastTestDate", $MetadataJson.dateUpdated)
        }

        if ([string]::IsNullOrWhiteSpace($properties.PublicLastTestDate)) {
            $properties.Add("PublicLastTestDate", $MetadataJson.dateUpdated)
        }

        # Preserve build numbers
        if ($existingRow) {
            if (-not [string]::IsNullOrWhiteSpace($existingRow.FairfaxDeploymentBuildNumber)) {
                $properties.Add("FairfaxDeploymentBuildNumber", $existingRow.FairfaxDeploymentBuildNumber)
            }
            else {
                $properties.Add("FairfaxDeploymentBuildNumber", "0")
            }

            if (-not [string]::IsNullOrWhiteSpace($existingRow.PublicDeploymentBuildNumber)) {
                $properties.Add("PublicDeploymentBuildNumber", $existingRow.PublicDeploymentBuildNumber)
            }
            else {
                $properties.Add("PublicDeploymentBuildNumber", "0")
            }

            # Remove existing row
            Write-Output "Removing existing row: $($existingRow.RowKey)"
            $existingRow | Remove-AzTableRow -Table $CloudTable
        }
        else {
            $properties.Add("FairfaxDeploymentBuildNumber", "0")
            $properties.Add("PublicDeploymentBuildNumber", "0")
        }

        # Add new/updated row
        Write-Output "Adding row: $RowKey"
        $params = @{
            Table        = $CloudTable
            Property     = $properties
            PartitionKey = $MetadataJson.type
            RowKey       = $RowKey
        }
        Add-AzTableRow @params

        $processedCount++
    }

    Write-Output "`nSummary:"
    Write-Output "- Total metadata files found: $($ArtifactFilePaths.Count)"
    Write-Output "- Processed: $processedCount"
    Write-Output "Table refresh completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

# Example usage:
# .\Refresh Quickstartstable.ps1 -BuildSourcesDirectory "C:\repos\azure-quickstart-templates" -StorageAccountName "myaccount" -StorageAccountKey "your-key"