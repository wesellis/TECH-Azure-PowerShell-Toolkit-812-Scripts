#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Applicationgateway Provisioning Tool

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
    We Enhanced Azure Applicationgateway Provisioning Tool

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGatewayName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVNetName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubnetName,
    [string]$WESkuName = " Standard_v2" ,
    [string]$WETier = " Standard_v2" ,
    [int]$WECapacity = 2
)

#region Functions

Write-WELog " Provisioning Application Gateway: $WEGatewayName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " SKU: $WESkuName" " INFO"
Write-WELog " Tier: $WETier" " INFO"
Write-WELog " Capacity: $WECapacity" " INFO"


$WEVNet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name $WEVNetName
$WESubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $WEVNet -Name $WESubnetName

Write-WELog " Using VNet: $WEVNetName" " INFO"
Write-WELog " Using Subnet: $WESubnetName" " INFO"


$WEPublicIpName = " $WEGatewayName-pip"
$params = @{
    ResourceGroupName = $WEResourceGroupName
    Sku = "Standard"
    Location = $WELocation
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $WEPublicIpName
}
$WEPublicIp @params

Write-WELog " Public IP created: $WEPublicIpName" " INFO"


$params = @{
    ErrorAction = "Stop"
    Subnet = $WESubnet
    Name = " gatewayIP01"
}
$WEGatewayIpConfig @params


$params = @{
    ErrorAction = "Stop"
    PublicIPAddress = $WEPublicIp
    Name = " frontendIP01"
}
$WEFrontendIpConfig @params


$params = @{
    ErrorAction = "Stop"
    Port = "80"
    Name = " frontendPort01"
}
$WEFrontendPort @params


$WEBackendPool -Name " backendPool01" -ErrorAction "Stop"


$params = @{
    ErrorAction = "Stop"
    Port = "80"
    CookieBasedAffinity = "Disabled"
    Name = " backendHttpSettings01"
    Protocol = "Http"
}
$WEBackendHttpSettings @params


$params = @{
    FrontendIPConfiguration = $WEFrontendIpConfig
    ErrorAction = "Stop"
    FrontendPort = $WEFrontendPort
    Name = " httpListener01"
    Protocol = "Http"
}
$WEHttpListener @params


$params = @{
    RuleType = "Basic"
    Name = " routingRule01"
    HttpListener = $WEHttpListener
    BackendAddressPool = $WEBackendPool
    ErrorAction = "Stop"
    BackendHttpSettings = $WEBackendHttpSettings
}
$WERoutingRule @params

; 
$params = @{
    Tier = $WETier
    ErrorAction = "Stop"
    Capacity = $WECapacity
    Name = $WESkuName
}
$WESku @params


Write-WELog " `nCreating Application Gateway (this may take 10-15 minutes)..." " INFO" ; 
$params = @{
    ResourceGroupName = $WEResourceGroupName
    Sku = $WESku
    GatewayIpConfiguration = $WEGatewayIpConfig
    FrontendPort = $WEFrontendPort
    Location = $WELocation
    BackendHttpSetting = $WEBackendHttpSettings
    HttpListener = $WEHttpListener
    RequestRoutingRule = $WERoutingRule
    BackendAddressPool = $WEBackendPool
    ErrorAction = "Stop"
    FrontendIpConfiguration = $WEFrontendIpConfig
    Name = $WEGatewayName
}
$WEAppGateway @params

Write-WELog " `nApplication Gateway $WEGatewayName provisioned successfully" " INFO"
Write-WELog " Public IP: $($WEPublicIp.IpAddress)" " INFO"
Write-WELog " Provisioning State: $($WEAppGateway.ProvisioningState)" " INFO"

Write-WELog " `nApplication Gateway provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
