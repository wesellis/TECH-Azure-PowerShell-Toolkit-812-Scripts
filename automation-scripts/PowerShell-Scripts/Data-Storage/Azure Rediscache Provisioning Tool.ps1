#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Rediscache Provisioning Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$CacheName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$SkuName = "Standard" ,
    [string]$SkuFamily = "C" ,
    [int]$SkuCapacity = 1,
    [bool]$EnableNonSslPort = $false,
    [hashtable]$RedisConfiguration = @{}
)
Write-Host "Provisioning Redis Cache: $CacheName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host "Location: $Location" "INFO"
Write-Host "SKU: $SkuName $SkuFamily$SkuCapacity" "INFO"
Write-Host "Non-SSL Port Enabled: $EnableNonSslPort" "INFO"

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
    Write-Host " `nApplying Redis Configuration:" "INFO"
    foreach ($Config in $RedisConfiguration.GetEnumerator()) {
        Write-Host "  $($Config.Key): $($Config.Value)" "INFO"
    }
}
Write-Host " `nRedis Cache $CacheName provisioned successfully" "INFO"
Write-Host "Host Name: $($RedisCache.HostName)" "INFO"
Write-Host "Port: $($RedisCache.Port)" "INFO"
Write-Host "SSL Port: $($RedisCache.SslPort)" "INFO"
Write-Host "Provisioning State: $($RedisCache.ProvisioningState)" "INFO"
Write-Host " `nAccess Keys: Available via Azure Portal or Get-AzRedisCacheKey -ErrorAction Stop cmdlet" "INFO"
Write-Host " `nRedis Cache provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

