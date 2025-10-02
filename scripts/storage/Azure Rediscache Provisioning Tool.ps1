#Requires -Version 7.4
#Requires -Modules Az.RedisCache

<#
.SYNOPSIS
    Azure Redis Cache Provisioning Tool

.DESCRIPTION
    Azure automation for provisioning Redis Cache instances

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$CacheName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter()]
    [string]$SkuName = "Standard",

    [Parameter()]
    [string]$SkuFamily = "C",

    [Parameter()]
    [int]$SkuCapacity = 1,

    [Parameter()]
    [bool]$EnableNonSslPort = $false,

    [Parameter()]
    [hashtable]$RedisConfiguration = @{}
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [Redis-Cache] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Provisioning Redis Cache: $CacheName" "INFO"
    Write-Log "Resource Group: $ResourceGroupName" "INFO"
    Write-Log "Location: $Location" "INFO"
    Write-Log "SKU: $SkuName $SkuFamily$SkuCapacity" "INFO"
    Write-Log "Non-SSL Port Enabled: $EnableNonSslPort" "INFO"

    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $CacheName
        Location = $Location
        Sku = $SkuName
        Size = "$SkuFamily$SkuCapacity"
        EnableNonSslPort = $EnableNonSslPort
        ErrorAction = "Stop"
    }

    if ($RedisConfiguration.Count -gt 0) {
        $params.RedisConfiguration = $RedisConfiguration
    }

    $RedisCache = New-AzRedisCache @params

    Write-Log "`nRedis Cache $CacheName provisioned successfully" "SUCCESS"
    Write-Log "Host Name: $($RedisCache.HostName)" "INFO"
    Write-Log "Port: $($RedisCache.Port)" "INFO"
    Write-Log "SSL Port: $($RedisCache.SslPort)" "INFO"
    Write-Log "Provisioning State: $($RedisCache.ProvisioningState)" "INFO"

    if ($RedisConfiguration.Count -gt 0) {
        Write-Log "`nApplied Redis Configuration:" "INFO"
        foreach ($Config in $RedisConfiguration.GetEnumerator()) {
            Write-Log "  $($Config.Key): $($Config.Value)" "INFO"
        }
    }

    Write-Log "`nAccess Keys: Available via Azure Portal or Get-AzRedisCacheKey cmdlet" "INFO"
    Write-Log "`nRedis Cache provisioning completed at $(Get-Date)" "SUCCESS"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}