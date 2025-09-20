#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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
Write-Host "`nAccess Keys: Available via Azure Portal or Get-AzRedisCacheKey -ErrorAction Stop cmdlet"
Write-Host "`nRedis Cache provisioning completed at $(Get-Date)"

