#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$CacheName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [string]$SkuFamily = "C",
    [int]$SkuCapacity = 1,
    [bool]$EnableNonSslPort = $false,
    [hashtable]$RedisConfiguration = @{}
)
Write-Output "Provisioning Redis Cache: $CacheName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $SkuName $SkuFamily$SkuCapacity"
Write-Output "Non-SSL Port Enabled: $EnableNonSslPort"
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
    Write-Output "`nApplying Redis Configuration:"
    foreach ($Config in $RedisConfiguration.GetEnumerator()) {
        Write-Output "  $($Config.Key): $($Config.Value)"
    }
}
Write-Output "`nRedis Cache $CacheName provisioned successfully"
Write-Output "Host Name: $($RedisCache.HostName)"
Write-Output "Port: $($RedisCache.Port)"
Write-Output "SSL Port: $($RedisCache.SslPort)"
Write-Output "Provisioning State: $($RedisCache.ProvisioningState)"
Write-Output "`nAccess Keys: Available via Azure Portal or Get-AzRedisCacheKey -ErrorAction Stop cmdlet"
Write-Output "`nRedis Cache provisioning completed at $(Get-Date)"



