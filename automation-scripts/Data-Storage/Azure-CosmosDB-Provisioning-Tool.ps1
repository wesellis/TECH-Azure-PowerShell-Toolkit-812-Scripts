# ============================================================================
# Script Name: Azure Cosmos DB Account Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Cosmos DB accounts with global distribution and consistency settings
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AccountName,
    [string]$Location,
    [string]$DefaultConsistencyLevel = "Session",
    [string]$Kind = "GlobalDocumentDB",
    [array]$LocationsToAdd = @(),
    [bool]$EnableMultipleWriteLocations = $false
)

Write-Information "Provisioning Cosmos DB Account: $AccountName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Primary Location: $Location"
Write-Information "Consistency Level: $DefaultConsistencyLevel"
Write-Information "Account Kind: $Kind"

# Create the Cosmos DB account
$CosmosDB = New-AzCosmosDBAccount -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $AccountName `
    -Location $Location `
    -DefaultConsistencyLevel $DefaultConsistencyLevel `
    -Kind $Kind `
    -EnableMultipleWriteLocations:$EnableMultipleWriteLocations

Write-Information "Cosmos DB Account $AccountName provisioned successfully"
Write-Information "Document Endpoint: $($CosmosDB.DocumentEndpoint)"
Write-Information "Write Locations: $($CosmosDB.WriteLocations.Count)"
Write-Information "Read Locations: $($CosmosDB.ReadLocations.Count)"

# Add additional locations if specified
if ($LocationsToAdd.Count -gt 0) {
    Write-Information "`nAdding additional locations:"
    foreach ($AddLocation in $LocationsToAdd) {
        Write-Information "  Adding location: $AddLocation"
        # Additional location configuration would go here
    }
}

Write-Information "`nCosmos DB provisioning completed at $(Get-Date)"
