#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Manage App Gateway

.DESCRIPTION
    Manage App Gateway
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$GatewayName,
    [string]$Location,
    [string]$VNetName,
    [string]$SubnetName,
    [string]$SkuName = "Standard_v2",
    [string]$Tier = "Standard_v2",
    [int]$Capacity = 2
)
Write-Output "Provisioning Application Gateway: $GatewayName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $SkuName"
Write-Output "Tier: $Tier"
Write-Output "Capacity: $Capacity"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName
Write-Output "Using VNet: $VNetName"
Write-Output "Using Subnet: $SubnetName"
$PublicIpName = "$GatewayName-pip"
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $PublicIpName
}
$PublicIp @params
Write-Output "Public IP created: $PublicIpName"
$params = @{
    ErrorAction = "Stop"
    Subnet = $Subnet
    Name = "gatewayIP01"
}
$GatewayIpConfig @params
$params = @{
    ErrorAction = "Stop"
    PublicIPAddress = $PublicIp
    Name = "frontendIP01"
}
$FrontendIpConfig @params
$params = @{
    ErrorAction = "Stop"
    Port = "80"
    Name = "frontendPort01"
}
$FrontendPort @params
$BackendPool -Name "backendPool01" -ErrorAction "Stop"
$params = @{
    ErrorAction = "Stop"
    Port = "80"
    CookieBasedAffinity = "Disabled"
    Name = "backendHttpSettings01"
    Protocol = "Http"
}
$BackendHttpSettings @params
$params = @{
    FrontendIPConfiguration = $FrontendIpConfig
    ErrorAction = "Stop"
    FrontendPort = $FrontendPort
    Name = "httpListener01"
    Protocol = "Http"
}
$HttpListener @params
$params = @{
    RuleType = "Basic"
    Name = "routingRule01"
    HttpListener = $HttpListener
    BackendAddressPool = $BackendPool
    ErrorAction = "Stop"
    BackendHttpSettings = $BackendHttpSettings
}
$RoutingRule @params
$params = @{
    Tier = $Tier
    ErrorAction = "Stop"
    Capacity = $Capacity
    Name = $SkuName
}
$Sku @params
Write-Output "`nCreating Application Gateway (this may take 10-15 minutes)..."
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    GatewayIpConfiguration = $GatewayIpConfig
    FrontendPort = $FrontendPort
    Location = $Location
    BackendHttpSetting = $BackendHttpSettings
    HttpListener = $HttpListener
    RequestRoutingRule = $RoutingRule
    BackendAddressPool = $BackendPool
    ErrorAction = "Stop"
    FrontendIpConfiguration = $FrontendIpConfig
    Name = $GatewayName
}
$AppGateway @params
Write-Output "`nApplication Gateway $GatewayName provisioned successfully"
Write-Output "Public IP: $($PublicIp.IpAddress)"
Write-Output "Provisioning State: $($AppGateway.ProvisioningState)"
Write-Output "`nApplication Gateway provisioning completed at $(Get-Date)"



