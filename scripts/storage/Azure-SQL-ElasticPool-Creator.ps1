#Requires -Version 7.4

<#`n.SYNOPSIS
    Manage SQL resources

.DESCRIPTION
    Manage SQL resources
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
Write-Output "Creating SQL Elastic Pool: $ElasticPoolName"
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
Write-Output "SQL Elastic Pool created successfully:"
Write-Output "Name: $($ElasticPool.ElasticPoolName)"
Write-Output "Server: $($ElasticPool.ServerName)"
Write-Output "Edition: $($ElasticPool.Edition)"
Write-Output "Pool DTU: $($ElasticPool.Dtu)"
Write-Output "Database DTU Min: $($ElasticPool.DatabaseDtuMin)"
Write-Output "Database DTU Max: $($ElasticPool.DatabaseDtuMax)"
Write-Output "State: $($ElasticPool.State)"
Write-Output "`nElastic Pool Benefits:"
Write-Output "Cost optimization for multiple databases"
Write-Output "Automatic resource balancing"
Write-Output "Simplified management"
Write-Output "Predictable pricing model"
Write-Output "`nNext Steps:"
Write-Output "1. Move existing databases to the pool"
Write-Output "2. Create new databases in the pool"
Write-Output "3. Monitor resource utilization"



