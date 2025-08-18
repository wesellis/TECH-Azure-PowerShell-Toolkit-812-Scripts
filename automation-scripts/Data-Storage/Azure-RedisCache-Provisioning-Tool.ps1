# ============================================================================
# Script Name: Azure Redis Cache Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Redis Cache instances with specified performance tiers
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$CacheName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [string]$SkuFamily = "C",
    [int]$SkuCapacity = 1,
    [bool]$EnableNonSslPort = $false,
    [hashtable]$RedisConfiguration = @{}
)

Write-Information "Provisioning Redis Cache: $CacheName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName $SkuFamily$SkuCapacity"
Write-Information "Non-SSL Port Enabled: $EnableNonSslPort"

# Create the Redis Cache
$RedisCache = New-AzRedisCache -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $CacheName `
    -Location $Location `
    -SkuName $SkuName `
    -SkuFamily $SkuFamily `
    -SkuCapacity $SkuCapacity `
    -EnableNonSslPort:$EnableNonSslPort

if ($RedisConfiguration.Count -gt 0) {
    Write-Information "`nApplying Redis Configuration:"
    foreach ($Config in $RedisConfiguration.GetEnumerator()) {
        Write-Information "  $($Config.Key): $($Config.Value)"
    }
}

Write-Information "`nRedis Cache $CacheName provisioned successfully"
Write-Information "Host Name: $($RedisCache.HostName)"
Write-Information "Port: $($RedisCache.Port)"
Write-Information "SSL Port: $($RedisCache.SslPort)"
Write-Information "Provisioning State: $($RedisCache.ProvisioningState)"

# Display access keys info (without showing actual keys)
Write-Information "`nAccess Keys: Available via Azure Portal or Get-AzRedisCacheKey -ErrorAction Stop cmdlet"

Write-Information "`nRedis Cache provisioning completed at $(Get-Date)"
