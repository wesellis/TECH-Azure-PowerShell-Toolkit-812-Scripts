<#
.SYNOPSIS
    Azure Sql Elasticpool Creator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ElasticPoolName,
    [Parameter()]
    [string]$Edition = "Standard" ,
    [Parameter()]
    [int]$PoolDtu = 100,
    [Parameter()]
    [int]$DatabaseDtuMin = 0,
    [Parameter()]
    [int]$DatabaseDtuMax = 100
)
Write-Host "Creating SQL Elastic Pool: $ElasticPoolName" "INFO"

$params = @{
    ResourceGroupName = $ResourceGroupName
    Dtu = $PoolDtu
    Edition = $Edition
    DatabaseDtuMax = $DatabaseDtuMax
    ServerName = $ServerName
    ElasticPoolName = $ElasticPoolName
    ErrorAction = "Stop"
    DatabaseDtuMin = $DatabaseDtuMin
}
$ElasticPool @params
Write-Host "SQL Elastic Pool created successfully:" "INFO"
Write-Host "Name: $($ElasticPool.ElasticPoolName)" "INFO"
Write-Host "Server: $($ElasticPool.ServerName)" "INFO"
Write-Host "Edition: $($ElasticPool.Edition)" "INFO"
Write-Host "Pool DTU: $($ElasticPool.Dtu)" "INFO"
Write-Host "Database DTU Min: $($ElasticPool.DatabaseDtuMin)" "INFO"
Write-Host "Database DTU Max: $($ElasticPool.DatabaseDtuMax)" "INFO"
Write-Host "State: $($ElasticPool.State)" "INFO"
Write-Host " `nElastic Pool Benefits:" "INFO"
Write-Host "Cost optimization for multiple databases" "INFO"
Write-Host "Automatic resource balancing" "INFO"
Write-Host "Simplified management" "INFO"
Write-Host "Predictable pricing model" "INFO"
Write-Host " `nNext Steps:" "INFO"
Write-Host " 1. Move existing databases to the pool" "INFO"
Write-Host " 2. Create new databases in the pool" "INFO"
Write-Host " 3. Monitor resource utilization" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n