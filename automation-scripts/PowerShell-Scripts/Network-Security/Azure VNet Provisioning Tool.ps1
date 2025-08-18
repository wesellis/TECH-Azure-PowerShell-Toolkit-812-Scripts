<#
.SYNOPSIS
    We Enhanced Azure Vnet Provisioning Tool

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
    [string]$WEVnetName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAddressPrefix,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WESubnetName = " default",
    [string]$WESubnetPrefix
)

Write-WELog " Provisioning Virtual Network: $WEVnetName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Address Prefix: $WEAddressPrefix" " INFO"


if ($WESubnetPrefix) {
    $WESubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $WESubnetName -AddressPrefix $WESubnetPrefix
    Write-WELog " Subnet: $WESubnetName ($WESubnetPrefix)" " INFO"
    
    # Create virtual network with subnet
    $WEVNet = New-AzVirtualNetwork `
        -ResourceGroupName $WEResourceGroupName `
        -Location $WELocation `
        -Name $WEVnetName `
        -AddressPrefix $WEAddressPrefix `
        -Subnet $WESubnetConfig
} else {
    # Create virtual network without subnet
   ;  $WEVNet = New-AzVirtualNetwork `
        -ResourceGroupName $WEResourceGroupName `
        -Location $WELocation `
        -Name $WEVnetName `
        -AddressPrefix $WEAddressPrefix
}

Write-WELog " Virtual Network $WEVnetName provisioned successfully" " INFO"
Write-WELog " VNet ID: $($WEVNet.Id)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
