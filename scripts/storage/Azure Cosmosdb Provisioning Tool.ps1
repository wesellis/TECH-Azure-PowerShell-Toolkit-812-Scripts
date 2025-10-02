#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Cosmosdb Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AccountName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$DefaultConsistencyLevel = "Session" ,
    [string]$Kind = "GlobalDocumentDB" ,
    [array]$LocationsToAdd = @(),
    [bool]$EnableMultipleWriteLocations = $false
)
Write-Output "Provisioning Cosmos DB Account: $AccountName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output "Primary Location: $Location" "INFO"
Write-Output "Consistency Level: $DefaultConsistencyLevel" "INFO"
Write-Output "Account Kind: $Kind" "INFO"
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Kind = $Kind
    ErrorAction = "Stop"
    DefaultConsistencyLevel = $DefaultConsistencyLevel
    Name = $AccountName
}
    [string]$CosmosDB @params
Write-Output "Cosmos DB Account $AccountName provisioned successfully" "INFO"
Write-Output "Document Endpoint: $($CosmosDB.DocumentEndpoint)" "INFO"
Write-Output "Write Locations: $($CosmosDB.WriteLocations.Count)" "INFO"
Write-Output "Read Locations: $($CosmosDB.ReadLocations.Count)" "INFO"
if ($LocationsToAdd.Count -gt 0) {
    Write-Output " `nAdding additional locations:" "INFO"
    foreach ($AddLocation in $LocationsToAdd) {
        Write-Output "Adding location: $AddLocation" "INFO"
    }
}
Write-Output " `nCosmos DB provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
