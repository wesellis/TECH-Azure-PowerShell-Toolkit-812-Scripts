# ============================================================================
# Script Name: Azure SQL Elastic Pool Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure SQL Elastic Pools for database resource sharing
# ============================================================================

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

Write-Host "Creating SQL Elastic Pool: $ElasticPoolName"

$ElasticPool = New-AzSqlElasticPool `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -ElasticPoolName $ElasticPoolName `
    -Edition $Edition `
    -Dtu $PoolDtu `
    -DatabaseDtuMin $DatabaseDtuMin `
    -DatabaseDtuMax $DatabaseDtuMax

Write-Host "✅ SQL Elastic Pool created successfully:"
Write-Host "  Name: $($ElasticPool.ElasticPoolName)"
Write-Host "  Server: $($ElasticPool.ServerName)"
Write-Host "  Edition: $($ElasticPool.Edition)"
Write-Host "  Pool DTU: $($ElasticPool.Dtu)"
Write-Host "  Database DTU Min: $($ElasticPool.DatabaseDtuMin)"
Write-Host "  Database DTU Max: $($ElasticPool.DatabaseDtuMax)"
Write-Host "  State: $($ElasticPool.State)"

Write-Host "`nElastic Pool Benefits:"
Write-Host "• Cost optimization for multiple databases"
Write-Host "• Automatic resource balancing"
Write-Host "• Simplified management"
Write-Host "• Predictable pricing model"

Write-Host "`nNext Steps:"
Write-Host "1. Move existing databases to the pool"
Write-Host "2. Create new databases in the pool"
Write-Host "3. Monitor resource utilization"
