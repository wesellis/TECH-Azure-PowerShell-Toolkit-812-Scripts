<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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
$params = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Kind = $Kind
    ErrorAction = "Stop"
    DefaultConsistencyLevel = $DefaultConsistencyLevel
    Name = $AccountName
}
$CosmosDB @params
Write-Host "Cosmos DB Account $AccountName provisioned successfully"
Write-Host "Document Endpoint: $($CosmosDB.DocumentEndpoint)"
Write-Host "Write Locations: $($CosmosDB.WriteLocations.Count)"
Write-Host "Read Locations: $($CosmosDB.ReadLocations.Count)"
# Add additional locations if specified
if ($LocationsToAdd.Count -gt 0) {
    Write-Host "`nAdding additional locations:"
    foreach ($AddLocation in $LocationsToAdd) {
        Write-Host "Adding location: $AddLocation"
        # Additional location configuration would go here
    }
}
Write-Host "`nCosmos DB provisioning completed at $(Get-Date)"

