#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Storage

<#
.SYNOPSIS
    Refresh Pull Request Table

.DESCRIPTION
    Azure automation script to refresh Pull Request table in Azure Table Storage.
    Checks GitHub API for closed PRs and removes them from the tracking table.
    Used for Azure Quickstarts template PR tracking.

.PARAMETER GitHubRepository
    GitHub repository name (defaults to BUILD_REPOSITORY_NAME environment variable)

.PARAMETER BuildSourcesDirectory
    Build sources directory (defaults to BUILD_SOURCESDIRECTORY environment variable)

.PARAMETER TableName
    Azure Table Storage table name (default: "QuickStartsMetadataServicePRs")

.PARAMETER StorageAccountResourceGroupName
    Resource group name for storage account (default: "azure-quickstarts-template-hash")

.PARAMETER StorageAccountName
    Storage account name (default: "azurequickstartsservice")

.PARAMETER StorageAccountKey
    Storage account access key (mandatory)

.PARAMETER BasicAuthCreds
    Basic authentication credentials for GitHub API (optional)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate Azure Storage and GitHub API access
    Cleans up closed PRs from tracking table
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GitHubRepository = $ENV:BUILD_REPOSITORY_NAME,

    [Parameter(Mandatory = $false)]
    [string]$BuildSourcesDirectory = $ENV:BUILD_SOURCESDIRECTORY,

    [Parameter(Mandatory = $false)]
    [string]$TableName = "QuickStartsMetadataServicePRs",

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountResourceGroupName = "azure-quickstarts-template-hash",

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "azurequickstartsservice",

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountKey,

    [Parameter(Mandatory = $false)]
    [string]$BasicAuthCreds
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Refreshing PR table for repository: $GitHubRepository"
    Write-Output "Storage Account: $StorageAccountName"
    Write-Output "Table Name: $TableName"

    # Create storage context
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment AzureCloud

    # Get cloud table reference
    $CloudTable = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable

    if (-not $CloudTable) {
        throw "Unable to get cloud table: $TableName"
    }

    # Get all rows in the PR table
    Write-Output "Getting all rows from PR table..."
    $rows = Get-AzTableRow -Table $CloudTable

    if (-not $rows) {
        Write-Output "No rows found in PR table"
        return
    }

    Write-Output "Found $($rows.Count) PR entries to check"

    # Check each PR status via GitHub API
    $removedCount = 0
    foreach ($r in $rows) {
        $PRUri = "https://api.github.com/repos/$($GitHubRepository)/pulls/$($r.pr)"

        Write-Verbose "Checking PR #$($r.pr) at: $PRUri"

        try {
            # Call GitHub API
            if ($BasicAuthCreds) {
                $response = Invoke-RestMethod -Uri $PRUri -Headers @{
                    Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($BasicAuthCreds)))"
                } -Method Get
            }
            else {
                $response = Invoke-RestMethod -Uri $PRUri -Method Get
            }

            Write-Output "PR #$($r.pr) is $($response.state)"

            # Remove closed PRs from table
            if ($response.state -eq 'closed') {
                Write-Output "Removing closed PR #$($r.pr) (RowKey: $($r.RowKey))"
                $r | Remove-AzTableRow -Table $CloudTable
                $removedCount++
            }
        }
        catch {
            Write-Warning "Failed to check PR #$($r.pr): $_"
            # Continue processing other PRs even if one fails
        }

        # Add small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
    }

    Write-Output "`nSummary:"
    Write-Output "- Total PRs checked: $($rows.Count)"
    Write-Output "- Closed PRs removed: $removedCount"
    Write-Output "- Active PRs remaining: $($rows.Count - $removedCount)"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

# Example usage:
# .\Refresh Prtable.ps1 -GitHubRepository "Azure/azure-quickstart-templates" -StorageAccountKey "your-key" -BasicAuthCreds "user:token"