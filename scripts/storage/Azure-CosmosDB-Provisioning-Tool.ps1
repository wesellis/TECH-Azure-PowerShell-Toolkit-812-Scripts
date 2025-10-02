#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AccountName,
    [string]$Location,
    [string]$DefaultConsistencyLevel = "Session",
    [string]$Kind = "GlobalDocumentDB",
    [array]$LocationsToAdd = @(),
    [bool]$EnableMultipleWriteLocations = $false
)
Write-Output "Provisioning Cosmos DB Account: $AccountName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Primary Location: $Location"
Write-Output "Consistency Level: $DefaultConsistencyLevel"
Write-Output "Account Kind: $Kind"
$params = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Kind = $Kind
    ErrorAction = "Stop"
    DefaultConsistencyLevel = $DefaultConsistencyLevel
    Name = $AccountName
}
$CosmosDB @params
Write-Output "Cosmos DB Account $AccountName provisioned successfully"
Write-Output "Document Endpoint: $($CosmosDB.DocumentEndpoint)"
Write-Output "Write Locations: $($CosmosDB.WriteLocations.Count)"
Write-Output "Read Locations: $($CosmosDB.ReadLocations.Count)"
if ($LocationsToAdd.Count -gt 0) {
    Write-Output "`nAdding additional locations:"
    foreach ($AddLocation in $LocationsToAdd) {
        Write-Output "Adding location: $AddLocation"
    }
}
Write-Output "`nCosmos DB provisioning completed at $(Get-Date)"



