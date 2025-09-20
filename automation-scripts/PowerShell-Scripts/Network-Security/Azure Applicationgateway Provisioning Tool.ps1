<#
.SYNOPSIS
    Azure Applicationgateway Provisioning Tool

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
Write-Host "Provisioning Application Gateway: $GatewayName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName"
Write-Host "Tier: $Tier"
Write-Host "Capacity: $Capacity"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName
Write-Host "Using VNet: $VNetName"
Write-Host "Using Subnet: $SubnetName"
$PublicIpName = " $GatewayName-pip"
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $PublicIpName
}
$PublicIp @params
Write-Host "Public IP created: $PublicIpName"
$params = @{
    ErrorAction = "Stop"
    Subnet = $Subnet
    Name = " gatewayIP01"
}
$GatewayIpConfig @params
$params = @{
    ErrorAction = "Stop"
    PublicIPAddress = $PublicIp
    Name = " frontendIP01"
}
$FrontendIpConfig @params
$params = @{
    ErrorAction = "Stop"
    Port = "80"
    Name = " frontendPort01"
}
$FrontendPort @params
$BackendPool -Name " backendPool01" -ErrorAction "Stop"
$params = @{
    ErrorAction = "Stop"
    Port = "80"
    CookieBasedAffinity = "Disabled"
    Name = " backendHttpSettings01"
    Protocol = "Http"
}
$BackendHttpSettings @params
$params = @{
    FrontendIPConfiguration = $FrontendIpConfig
    ErrorAction = "Stop"
    FrontendPort = $FrontendPort
    Name = " httpListener01"
    Protocol = "Http"
}
$HttpListener @params
$params = @{
    RuleType = "Basic"
    Name = " routingRule01"
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
Write-Host " `nCreating Application Gateway (this may take 10-15 minutes)..." ;
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
Write-Host " `nApplication Gateway $GatewayName provisioned successfully"
Write-Host "Public IP: $($PublicIp.IpAddress)"
Write-Host "Provisioning State: $($AppGateway.ProvisioningState)"
Write-Host " `nApplication Gateway provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n