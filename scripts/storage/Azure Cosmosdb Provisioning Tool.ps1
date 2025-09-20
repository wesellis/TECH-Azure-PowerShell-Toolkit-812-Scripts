#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure Cosmosdb Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
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
Write-Host "Provisioning Cosmos DB Account: $AccountName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host "Primary Location: $Location" "INFO"
Write-Host "Consistency Level: $DefaultConsistencyLevel" "INFO"
Write-Host "Account Kind: $Kind" "INFO"

$params = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Kind = $Kind
    ErrorAction = "Stop"
    DefaultConsistencyLevel = $DefaultConsistencyLevel
    Name = $AccountName
}
$CosmosDB @params
Write-Host "Cosmos DB Account $AccountName provisioned successfully" "INFO"
Write-Host "Document Endpoint: $($CosmosDB.DocumentEndpoint)" "INFO"
Write-Host "Write Locations: $($CosmosDB.WriteLocations.Count)" "INFO"
Write-Host "Read Locations: $($CosmosDB.ReadLocations.Count)" "INFO"
if ($LocationsToAdd.Count -gt 0) {
    Write-Host " `nAdding additional locations:" "INFO"
    foreach ($AddLocation in $LocationsToAdd) {
        Write-Host "Adding location: $AddLocation" "INFO"
        # Additional location configuration would go here
    }
}
Write-Host " `nCosmos DB provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
