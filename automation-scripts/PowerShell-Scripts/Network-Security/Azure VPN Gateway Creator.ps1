#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Vpn Gateway Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Vpn Gateway Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGatewayName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVNetName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [string]$WEGatewaySku = " VpnGw1"
)

#region Functions

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
$params = @{
    ErrorAction = "Stop"
    AllocationMethod = "Dynamic"
    ResourceGroupName = $WEResourceGroupName
    Name = $WEGatewayIpName
    Location = $WELocation
}
$WEGatewayIp @params

; 
$params = @{
    ErrorAction = "Stop"
    PublicIpAddressId = $WEGatewayIp.Id
    SubnetId = $WEGatewaySubnet.Id
    Name = " gatewayConfig"
}
$WEGatewayIpConfig @params


Write-WELog " Creating VPN Gateway (this may take 30-45 minutes)..." " INFO" ; 
$params = @{
    ResourceGroupName = $WEResourceGroupName
    Location = $WELocation
    GatewaySku = $WEGatewaySku
    VpnType = " RouteBased"
    IpConfigurations = $WEGatewayIpConfig
    GatewayType = " Vpn"
    ErrorAction = "Stop"
    Name = $WEGatewayName
}
$WEGateway @params

Write-WELog "  VPN Gateway created successfully:" " INFO"
Write-WELog "  Name: $($WEGateway.Name)" " INFO"
Write-WELog "  Type: $($WEGateway.GatewayType)" " INFO"
Write-WELog "  SKU: $($WEGateway.Sku.Name)" " INFO"
Write-WELog "  Public IP: $($WEGatewayIp.IpAddress)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
