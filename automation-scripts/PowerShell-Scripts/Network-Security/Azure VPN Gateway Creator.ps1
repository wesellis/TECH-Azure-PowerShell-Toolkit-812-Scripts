<#
.SYNOPSIS
    We Enhanced Azure Vpn Gateway Creator

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
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGatewayName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVNetName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [string]$WEGatewaySku = " VpnGw1"
)

Write-WELog " Creating VPN Gateway: $WEGatewayName" " INFO"


$WEVNet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name $WEVNetName


$WEGatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $WEVNet -Name " GatewaySubnet" -ErrorAction SilentlyContinue
if (-not $WEGatewaySubnet) {
    Write-WELog " Creating GatewaySubnet..." " INFO"
    Add-AzVirtualNetworkSubnetConfig -Name " GatewaySubnet" -VirtualNetwork $WEVNet -AddressPrefix " 10.0.255.0/27"
    Set-AzVirtualNetwork -VirtualNetwork $WEVNet
    $WEVNet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name $WEVNetName
    $WEGatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $WEVNet -Name " GatewaySubnet"
}


$WEGatewayIpName = " $WEGatewayName-pip"
$WEGatewayIp = New-AzPublicIpAddress `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEGatewayIpName `
    -Location $WELocation `
    -AllocationMethod Dynamic


$WEGatewayIpConfig = New-AzVirtualNetworkGatewayIpConfig `
    -Name " gatewayConfig" `
    -SubnetId $WEGatewaySubnet.Id `
    -PublicIpAddressId $WEGatewayIp.Id


Write-WELog " Creating VPN Gateway (this may take 30-45 minutes)..." " INFO"; 
$WEGateway = New-AzVirtualNetworkGateway `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEGatewayName `
    -Location $WELocation `
    -IpConfigurations $WEGatewayIpConfig `
    -GatewayType " Vpn" `
    -VpnType " RouteBased" `
    -GatewaySku $WEGatewaySku

Write-WELog " ✅ VPN Gateway created successfully:" " INFO"
Write-WELog "  Name: $($WEGateway.Name)" " INFO"
Write-WELog "  Type: $($WEGateway.GatewayType)" " INFO"
Write-WELog "  SKU: $($WEGateway.Sku.Name)" " INFO"
Write-WELog "  Public IP: $($WEGatewayIp.IpAddress)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
