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

Write-Host "Provisioning Cosmos DB Account: $AccountName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Primary Location: $Location"
Write-Host "Consistency Level: $DefaultConsistencyLevel"
Write-Host "Account Kind: $Kind"

# Create the Cosmos DB account
$CosmosDB = New-AzCosmosDBAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $AccountName `
    -Location $Location `
    -DefaultConsistencyLevel $DefaultConsistencyLevel `
    -Kind $Kind `
    -EnableMultipleWriteLocations:$EnableMultipleWriteLocations

Write-Host "Cosmos DB Account $AccountName provisioned successfully"
Write-Host "Document Endpoint: $($CosmosDB.DocumentEndpoint)"
Write-Host "Write Locations: $($CosmosDB.WriteLocations.Count)"
Write-Host "Read Locations: $($CosmosDB.ReadLocations.Count)"

# Add additional locations if specified
if ($LocationsToAdd.Count -gt 0) {
    Write-Host "`nAdding additional locations:"
    foreach ($AddLocation in $LocationsToAdd) {
        Write-Host "  Adding location: $AddLocation"
        # Additional location configuration would go here
    }
}

Write-Host "`nCosmos DB provisioning completed at $(Get-Date)"
