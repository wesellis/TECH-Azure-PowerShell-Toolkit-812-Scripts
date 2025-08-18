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

Write-Information "Creating SQL Elastic Pool: $ElasticPoolName"

$ElasticPool = New-AzSqlElasticPool -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -ElasticPoolName $ElasticPoolName `
    -Edition $Edition `
    -Dtu $PoolDtu `
    -DatabaseDtuMin $DatabaseDtuMin `
    -DatabaseDtuMax $DatabaseDtuMax

Write-Information "✅ SQL Elastic Pool created successfully:"
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
