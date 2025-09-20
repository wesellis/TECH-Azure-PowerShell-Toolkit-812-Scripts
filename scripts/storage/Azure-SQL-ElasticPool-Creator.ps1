#Requires -Version 7.0

<#`n.SYNOPSIS
    Manage SQL resources

.DESCRIPTION
    Manage SQL resources
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ServerName,
    [Parameter(Mandatory)]
    [string]$ElasticPoolName,
    [Parameter()]
    [string]$Edition = "Standard",
    [Parameter()]
    [int]$PoolDtu = 100,
    [Parameter()]
    [int]$DatabaseDtuMin = 0,
    [Parameter()]
    [int]$DatabaseDtuMax = 100
)
Write-Host "Creating SQL Elastic Pool: $ElasticPoolName"
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
Write-Host "SQL Elastic Pool created successfully:"
Write-Host "Name: $($ElasticPool.ElasticPoolName)"
Write-Host "Server: $($ElasticPool.ServerName)"
Write-Host "Edition: $($ElasticPool.Edition)"
Write-Host "Pool DTU: $($ElasticPool.Dtu)"
Write-Host "Database DTU Min: $($ElasticPool.DatabaseDtuMin)"
Write-Host "Database DTU Max: $($ElasticPool.DatabaseDtuMax)"
Write-Host "State: $($ElasticPool.State)"
Write-Host "`nElastic Pool Benefits:"
Write-Host "Cost optimization for multiple databases"
Write-Host "Automatic resource balancing"
Write-Host "Simplified management"
Write-Host "Predictable pricing model"
Write-Host "`nNext Steps:"
Write-Host "1. Move existing databases to the pool"
Write-Host "2. Create new databases in the pool"
Write-Host "3. Monitor resource utilization"

