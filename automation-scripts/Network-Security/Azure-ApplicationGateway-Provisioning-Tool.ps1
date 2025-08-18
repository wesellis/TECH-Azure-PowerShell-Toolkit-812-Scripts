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
$PublicIp = New-AzPublicIpAddress -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Name $PublicIpName `
    -AllocationMethod Static `
    -Sku Standard

Write-Information "Public IP created: $PublicIpName"

# Create Application Gateway IP configuration
$GatewayIpConfig = New-AzApplicationGatewayIPConfiguration -ErrorAction Stop `
    -Name "gatewayIP01" `
    -Subnet $Subnet

# Create frontend IP configuration
$FrontendIpConfig = New-AzApplicationGatewayFrontendIPConfig -ErrorAction Stop `
    -Name "frontendIP01" `
    -PublicIPAddress $PublicIp

# Create frontend port
$FrontendPort = New-AzApplicationGatewayFrontendPort -ErrorAction Stop `
    -Name "frontendPort01" `
    -Port 80

# Create backend address pool
$BackendPool = New-AzApplicationGatewayBackendAddressPool -ErrorAction Stop `
    -Name "backendPool01"

# Create backend HTTP settings
$BackendHttpSettings = New-AzApplicationGatewayBackendHttpSetting -ErrorAction Stop `
    -Name "backendHttpSettings01" `
    -Port 80 `
    -Protocol Http `
    -CookieBasedAffinity Disabled

# Create HTTP listener
$HttpListener = New-AzApplicationGatewayHttpListener -ErrorAction Stop `
    -Name "httpListener01" `
    -Protocol Http `
    -FrontendIPConfiguration $FrontendIpConfig `
    -FrontendPort $FrontendPort

# Create request routing rule
$RoutingRule = New-AzApplicationGatewayRequestRoutingRule -ErrorAction Stop `
    -Name "routingRule01" `
    -RuleType Basic `
    -HttpListener $HttpListener `
    -BackendAddressPool $BackendPool `
    -BackendHttpSettings $BackendHttpSettings

# Create SKU
$Sku = New-AzApplicationGatewaySku -ErrorAction Stop `
    -Name $SkuName `
    -Tier $Tier `
    -Capacity $Capacity

# Create the Application Gateway
Write-Information "`nCreating Application Gateway (this may take 10-15 minutes)..."
$AppGateway = New-AzApplicationGateway -ErrorAction Stop `
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

Write-Information "`nApplication Gateway $GatewayName provisioned successfully"
Write-Information "Public IP: $($PublicIp.IpAddress)"
Write-Information "Provisioning State: $($AppGateway.ProvisioningState)"

Write-Information "`nApplication Gateway provisioning completed at $(Get-Date)"
