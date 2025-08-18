<#
.SYNOPSIS
    We Enhanced Azure Rediscache Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WECacheName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WESkuName = " Standard",
    [string]$WESkuFamily = " C",
    [int]$WESkuCapacity = 1,
    [bool]$WEEnableNonSslPort = $false,
    [hashtable]$WERedisConfiguration = @{}
)

Write-WELog " Provisioning Redis Cache: $WECacheName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " SKU: $WESkuName $WESkuFamily$WESkuCapacity" " INFO"
Write-WELog " Non-SSL Port Enabled: $WEEnableNonSslPort" " INFO"

; 
$WERedisCache = New-AzRedisCache `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WECacheName `
    -Location $WELocation `
    -SkuName $WESkuName `
    -SkuFamily $WESkuFamily `
    -SkuCapacity $WESkuCapacity `
    -EnableNonSslPort:$WEEnableNonSslPort

if ($WERedisConfiguration.Count -gt 0) {
    Write-WELog " `nApplying Redis Configuration:" " INFO"
    foreach ($WEConfig in $WERedisConfiguration.GetEnumerator()) {
        Write-WELog "  $($WEConfig.Key): $($WEConfig.Value)" " INFO"
    }
}

Write-WELog " `nRedis Cache $WECacheName provisioned successfully" " INFO"
Write-WELog " Host Name: $($WERedisCache.HostName)" " INFO"
Write-WELog " Port: $($WERedisCache.Port)" " INFO"
Write-WELog " SSL Port: $($WERedisCache.SslPort)" " INFO"
Write-WELog " Provisioning State: $($WERedisCache.ProvisioningState)" " INFO"


Write-WELog " `nAccess Keys: Available via Azure Portal or Get-AzRedisCacheKey cmdlet" " INFO"

Write-WELog " `nRedis Cache provisioning completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
