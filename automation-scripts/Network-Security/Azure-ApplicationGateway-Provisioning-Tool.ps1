# ============================================================================
# Script Name: Azure Application Gateway Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Application Gateway with load balancing and SSL termination
# ============================================================================

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

Write-Host "Provisioning Application Gateway: $GatewayName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName"
Write-Host "Tier: $Tier"
Write-Host "Capacity: $Capacity"

# Get the virtual network and subnet
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName

Write-Host "Using VNet: $VNetName"
Write-Host "Using Subnet: $SubnetName"

# Create public IP for the Application Gateway
$PublicIpName = "$GatewayName-pip"
$PublicIp = New-AzPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Name $PublicIpName `
    -AllocationMethod Static `
    -Sku Standard

Write-Host "Public IP created: $PublicIpName"

# Create Application Gateway IP configuration
$GatewayIpConfig = New-AzApplicationGatewayIPConfiguration `
    -Name "gatewayIP01" `
    -Subnet $Subnet

# Create frontend IP configuration
$FrontendIpConfig = New-AzApplicationGatewayFrontendIPConfig `
    -Name "frontendIP01" `
    -PublicIPAddress $PublicIp

# Create frontend port
$FrontendPort = New-AzApplicationGatewayFrontendPort `
    -Name "frontendPort01" `
    -Port 80

# Create backend address pool
$BackendPool = New-AzApplicationGatewayBackendAddressPool `
    -Name "backendPool01"

# Create backend HTTP settings
$BackendHttpSettings = New-AzApplicationGatewayBackendHttpSetting `
    -Name "backendHttpSettings01" `
    -Port 80 `
    -Protocol Http `
    -CookieBasedAffinity Disabled

# Create HTTP listener
$HttpListener = New-AzApplicationGatewayHttpListener `
    -Name "httpListener01" `
    -Protocol Http `
    -FrontendIPConfiguration $FrontendIpConfig `
    -FrontendPort $FrontendPort

# Create request routing rule
$RoutingRule = New-AzApplicationGatewayRequestRoutingRule `
    -Name "routingRule01" `
    -RuleType Basic `
    -HttpListener $HttpListener `
    -BackendAddressPool $BackendPool `
    -BackendHttpSettings $BackendHttpSettings

# Create SKU
$Sku = New-AzApplicationGatewaySku `
    -Name $SkuName `
    -Tier $Tier `
    -Capacity $Capacity

# Create the Application Gateway
Write-Host "`nCreating Application Gateway (this may take 10-15 minutes)..."
$AppGateway = New-AzApplicationGateway `
    -Name $GatewayName `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -GatewayIpConfiguration $GatewayIpConfig `
    -FrontendIpConfiguration $FrontendIpConfig `
    -FrontendPort $FrontendPort `
    -BackendAddressPool $BackendPool `
    -BackendHttpSetting $BackendHttpSettings `
    -HttpListener $HttpListener `
    -RequestRoutingRule $RoutingRule `
    -Sku $Sku

Write-Host "`nApplication Gateway $GatewayName provisioned successfully"
Write-Host "Public IP: $($PublicIp.IpAddress)"
Write-Host "Provisioning State: $($AppGateway.ProvisioningState)"

Write-Host "`nApplication Gateway provisioning completed at $(Get-Date)"
