#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$GatewayName,
    [string]$Location,
    [string]$VNetName,
    [string]$SubnetName,
    [string]$SkuName = "Standard_v2",
    [string]$Tier = "Standard_v2",
    [int]$Capacity = 2
)

#region Functions

Write-Information "Provisioning Application Gateway: $GatewayName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName"
Write-Information "Tier: $Tier"
Write-Information "Capacity: $Capacity"

# Get the virtual network and subnet
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName

Write-Information "Using VNet: $VNetName"
Write-Information "Using Subnet: $SubnetName"

# Create public IP for the Application Gateway
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

Write-Information "Public IP created: $PublicIpName"

# Create Application Gateway IP configuration
$params = @{
    ErrorAction = "Stop"
    Subnet = $Subnet
    Name = "gatewayIP01"
}
$GatewayIpConfig @params

# Create frontend IP configuration
$params = @{
    ErrorAction = "Stop"
    PublicIPAddress = $PublicIp
    Name = "frontendIP01"
}
$FrontendIpConfig @params

# Create frontend port
$params = @{
    ErrorAction = "Stop"
    Port = "80"
    Name = "frontendPort01"
}
$FrontendPort @params

# Create backend address pool
$BackendPool -Name "backendPool01" -ErrorAction "Stop"

# Create backend HTTP settings
$params = @{
    ErrorAction = "Stop"
    Port = "80"
    CookieBasedAffinity = "Disabled"
    Name = "backendHttpSettings01"
    Protocol = "Http"
}
$BackendHttpSettings @params

# Create HTTP listener
$params = @{
    FrontendIPConfiguration = $FrontendIpConfig
    ErrorAction = "Stop"
    FrontendPort = $FrontendPort
    Name = "httpListener01"
    Protocol = "Http"
}
$HttpListener @params

# Create request routing rule
$params = @{
    RuleType = "Basic"
    Name = "routingRule01"
    HttpListener = $HttpListener
    BackendAddressPool = $BackendPool
    ErrorAction = "Stop"
    BackendHttpSettings = $BackendHttpSettings
}
$RoutingRule @params

# Create SKU
$params = @{
    Tier = $Tier
    ErrorAction = "Stop"
    Capacity = $Capacity
    Name = $SkuName
}
$Sku @params

# Create the Application Gateway
Write-Information "`nCreating Application Gateway (this may take 10-15 minutes)..."
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

Write-Information "`nApplication Gateway $GatewayName provisioned successfully"
Write-Information "Public IP: $($PublicIp.IpAddress)"
Write-Information "Provisioning State: $($AppGateway.ProvisioningState)"

Write-Information "`nApplication Gateway provisioning completed at $(Get-Date)"


#endregion
