#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Azure Vpn Gateway Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
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
Write-Output "Creating VPN Gateway: $GatewayName" "INFO"
    [string]$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    [string]$GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet" -ErrorAction SilentlyContinue
if (-not $GatewaySubnet) {
    Write-Output "Creating GatewaySubnet..." "INFO"
    Add-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $VNet -AddressPrefix " 10.0.255.0/27"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    [string]$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    [string]$GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet"
}
    [string]$GatewayIpName = " $GatewayName-pip"
    $params = @{
    ErrorAction = "Stop"
    AllocationMethod = "Dynamic"
    ResourceGroupName = $ResourceGroupName
    Name = $GatewayIpName
    Location = $Location
}
    [string]$GatewayIp @params
    $params = @{
    ErrorAction = "Stop"
    PublicIpAddressId = $GatewayIp.Id
    SubnetId = $GatewaySubnet.Id
    Name = " gatewayConfig"
}
    [string]$GatewayIpConfig @params
Write-Output "Creating VPN Gateway (this may take 30-45 minutes)..." "INFO" ;
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
    [string]$Gateway @params
Write-Output "VPN Gateway created successfully:" "INFO"
Write-Output "Name: $($Gateway.Name)" "INFO"
Write-Output "Type: $($Gateway.GatewayType)" "INFO"
Write-Output "SKU: $($Gateway.Sku.Name)" "INFO"
Write-Output "Public IP: $($GatewayIp.IpAddress)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
