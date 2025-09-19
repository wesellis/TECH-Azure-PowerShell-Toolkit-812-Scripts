#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$ElasticPoolName,
    
    [Parameter(Mandatory=$false)]
    [string]$Edition = "Standard",
    
    [Parameter(Mandatory=$false)]
    [int]$PoolDtu = 100,
    
    [Parameter(Mandatory=$false)]
    [int]$DatabaseDtuMin = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$DatabaseDtuMax = 100
)

#region Functions

Write-Information "Creating SQL Elastic Pool: $ElasticPoolName"

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

Write-Information " SQL Elastic Pool created successfully:"
Write-Information "  Name: $($ElasticPool.ElasticPoolName)"
Write-Information "  Server: $($ElasticPool.ServerName)"
Write-Information "  Edition: $($ElasticPool.Edition)"
Write-Information "  Pool DTU: $($ElasticPool.Dtu)"
Write-Information "  Database DTU Min: $($ElasticPool.DatabaseDtuMin)"
Write-Information "  Database DTU Max: $($ElasticPool.DatabaseDtuMax)"
Write-Information "  State: $($ElasticPool.State)"

Write-Information "`nElastic Pool Benefits:"
Write-Information "• Cost optimization for multiple databases"
Write-Information "• Automatic resource balancing"
Write-Information "• Simplified management"
Write-Information "• Predictable pricing model"

Write-Information "`nNext Steps:"
Write-Information "1. Move existing databases to the pool"
Write-Information "2. Create new databases in the pool"
Write-Information "3. Monitor resource utilization"


#endregion
