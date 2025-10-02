#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Azure Applicationgateway Provisioning Tool

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GatewayName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VNetName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubnetName,
    [string]$SkuName = "Standard_v2" ,
    [string]$Tier = "Standard_v2" ,
    [int]$Capacity = 2
)
Write-Output "Provisioning Application Gateway: $GatewayName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $SkuName"
Write-Output "Tier: $Tier"
Write-Output "Capacity: $Capacity"
    [string]$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    [string]$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName
Write-Output "Using VNet: $VNetName"
Write-Output "Using Subnet: $SubnetName"
    [string]$PublicIpName = " $GatewayName-pip"
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $PublicIpName
}
    [string]$PublicIp @params
Write-Output "Public IP created: $PublicIpName"
    $params = @{
    ErrorAction = "Stop"
    Subnet = $Subnet
    Name = " gatewayIP01"
}
    [string]$GatewayIpConfig @params
    $params = @{
    ErrorAction = "Stop"
    PublicIPAddress = $PublicIp
    Name = " frontendIP01"
}
    [string]$FrontendIpConfig @params
    $params = @{
    ErrorAction = "Stop"
    Port = "80"
    Name = " frontendPort01"
}
    [string]$FrontendPort @params
    [string]$BackendPool -Name " backendPool01" -ErrorAction "Stop"
    $params = @{
    ErrorAction = "Stop"
    Port = "80"
    CookieBasedAffinity = "Disabled"
    Name = " backendHttpSettings01"
    Protocol = "Http"
}
    [string]$BackendHttpSettings @params
    $params = @{
    FrontendIPConfiguration = $FrontendIpConfig
    ErrorAction = "Stop"
    FrontendPort = $FrontendPort
    Name = " httpListener01"
    Protocol = "Http"
}
    [string]$HttpListener @params
    $params = @{
    RuleType = "Basic"
    Name = " routingRule01"
    HttpListener = $HttpListener
    BackendAddressPool = $BackendPool
    ErrorAction = "Stop"
    BackendHttpSettings = $BackendHttpSettings
}
    [string]$RoutingRule @params
    $params = @{
    Tier = $Tier
    ErrorAction = "Stop"
    Capacity = $Capacity
    Name = $SkuName
}
    [string]$Sku @params
Write-Output " `nCreating Application Gateway (this may take 10-15 minutes)..." ;
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
    [string]$AppGateway @params
Write-Output " `nApplication Gateway $GatewayName provisioned successfully"
Write-Output "Public IP: $($PublicIp.IpAddress)"
Write-Output "Provisioning State: $($AppGateway.ProvisioningState)"
Write-Output " `nApplication Gateway provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
