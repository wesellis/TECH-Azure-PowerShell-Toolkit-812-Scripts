#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Sql Elasticpool Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
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
    $Edition = "Standard" ,
    [Parameter()]
    [int]$PoolDtu = 100,
    [Parameter()]
    [int]$DatabaseDtuMin = 0,
    [Parameter()]
    [int]$DatabaseDtuMax = 100
)
Write-Output "Creating SQL Elastic Pool: $ElasticPoolName" "INFO"
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
    [string]$ElasticPool @params
Write-Output "SQL Elastic Pool created successfully:" "INFO"
Write-Output "Name: $($ElasticPool.ElasticPoolName)" "INFO"
Write-Output "Server: $($ElasticPool.ServerName)" "INFO"
Write-Output "Edition: $($ElasticPool.Edition)" "INFO"
Write-Output "Pool DTU: $($ElasticPool.Dtu)" "INFO"
Write-Output "Database DTU Min: $($ElasticPool.DatabaseDtuMin)" "INFO"
Write-Output "Database DTU Max: $($ElasticPool.DatabaseDtuMax)" "INFO"
Write-Output "State: $($ElasticPool.State)" "INFO"
Write-Output " `nElastic Pool Benefits:" "INFO"
Write-Output "Cost optimization for multiple databases" "INFO"
Write-Output "Automatic resource balancing" "INFO"
Write-Output "Simplified management" "INFO"
Write-Output "Predictable pricing model" "INFO"
Write-Output " `nNext Steps:" "INFO"
Write-Output " 1. Move existing databases to the pool" "INFO"
Write-Output " 2. Create new databases in the pool" "INFO"
Write-Output " 3. Monitor resource utilization" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
