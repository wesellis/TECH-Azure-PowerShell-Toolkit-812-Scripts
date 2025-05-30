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

Write-Host "Provisioning Redis Cache: $CacheName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName $SkuFamily$SkuCapacity"
Write-Host "Non-SSL Port Enabled: $EnableNonSslPort"

# Create the Redis Cache
$RedisCache = New-AzRedisCache `
    -ResourceGroupName $ResourceGroupName `
    -Name $CacheName `
    -Location $Location `
    -SkuName $SkuName `
    -SkuFamily $SkuFamily `
    -SkuCapacity $SkuCapacity `
    -EnableNonSslPort:$EnableNonSslPort

if ($RedisConfiguration.Count -gt 0) {
    Write-Host "`nApplying Redis Configuration:"
    foreach ($Config in $RedisConfiguration.GetEnumerator()) {
        Write-Host "  $($Config.Key): $($Config.Value)"
    }
}

Write-Host "`nRedis Cache $CacheName provisioned successfully"
Write-Host "Host Name: $($RedisCache.HostName)"
Write-Host "Port: $($RedisCache.Port)"
Write-Host "SSL Port: $($RedisCache.SslPort)"
Write-Host "Provisioning State: $($RedisCache.ProvisioningState)"

# Display access keys info (without showing actual keys)
Write-Host "`nAccess Keys: Available via Azure Portal or Get-AzRedisCacheKey cmdlet"

Write-Host "`nRedis Cache provisioning completed at $(Get-Date)"
