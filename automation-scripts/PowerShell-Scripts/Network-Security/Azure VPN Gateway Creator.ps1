#Requires -Version 7.0
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Azure Vpn Gateway Creator

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
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GatewayName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VNetName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [string]$GatewaySku = "VpnGw1"
)
Write-Host "Creating VPN Gateway: $GatewayName" "INFO"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet" -ErrorAction SilentlyContinue
if (-not $GatewaySubnet) {
    Write-Host "Creating GatewaySubnet..." "INFO"
    Add-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $VNet -AddressPrefix " 10.0.255.0/27"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    $VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    $GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet"
}
$GatewayIpName = " $GatewayName-pip"
$params = @{
    ErrorAction = "Stop"
    AllocationMethod = "Dynamic"
    ResourceGroupName = $ResourceGroupName
    Name = $GatewayIpName
    Location = $Location
}
$GatewayIp @params

$params = @{
    ErrorAction = "Stop"
    PublicIpAddressId = $GatewayIp.Id
    SubnetId = $GatewaySubnet.Id
    Name = " gatewayConfig"
}
$GatewayIpConfig @params
Write-Host "Creating VPN Gateway (this may take 30-45 minutes)..." "INFO" ;
$params = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    GatewaySku = $GatewaySku
    VpnType = "RouteBased"
    IpConfigurations = $GatewayIpConfig
    GatewayType = "Vpn"
    ErrorAction = "Stop"
    Name = $GatewayName
}
$Gateway @params
Write-Host "VPN Gateway created successfully:" "INFO"
Write-Host "Name: $($Gateway.Name)" "INFO"
Write-Host "Type: $($Gateway.GatewayType)" "INFO"
Write-Host "SKU: $($Gateway.Sku.Name)" "INFO"
Write-Host "Public IP: $($GatewayIp.IpAddress)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

