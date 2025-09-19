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
    [string]$ResourceGroupName,
    [string]$CacheName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [string]$SkuFamily = "C",
    [int]$SkuCapacity = 1,
    [bool]$EnableNonSslPort = $false,
    [hashtable]$RedisConfiguration = @{}
)

#region Functions

Write-Information "Provisioning Redis Cache: $CacheName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName $SkuFamily$SkuCapacity"
Write-Information "Non-SSL Port Enabled: $EnableNonSslPort"

# Create the Redis Cache
$params = @{
    ResourceGroupName = $ResourceGroupName
    SkuName = $SkuName
    Location = $Location
    SkuFamily = $SkuFamily
    SkuCapacity = $SkuCapacity
    ErrorAction = "Stop"
    Name = $CacheName
}
$RedisCache @params

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


#endregion
