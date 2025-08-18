<#
.SYNOPSIS
    Azure Applicationgateway Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
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
$WEPublicIp = New-AzPublicIpAddress `
    -ResourceGroupName $WEResourceGroupName `
    -Location $WELocation `
    -Name $WEPublicIpName `
    -AllocationMethod Static `
    -Sku Standard

Write-WELog " Public IP created: $WEPublicIpName" " INFO"


$WEGatewayIpConfig = New-AzApplicationGatewayIPConfiguration `
    -Name " gatewayIP01" `
    -Subnet $WESubnet


$WEFrontendIpConfig = New-AzApplicationGatewayFrontendIPConfig `
    -Name " frontendIP01" `
    -PublicIPAddress $WEPublicIp


$WEFrontendPort = New-AzApplicationGatewayFrontendPort `
    -Name " frontendPort01" `
    -Port 80


$WEBackendPool = New-AzApplicationGatewayBackendAddressPool `
    -Name " backendPool01"


$WEBackendHttpSettings = New-AzApplicationGatewayBackendHttpSetting `
    -Name " backendHttpSettings01" `
    -Port 80 `
    -Protocol Http `
    -CookieBasedAffinity Disabled


$WEHttpListener = New-AzApplicationGatewayHttpListener `
    -Name " httpListener01" `
    -Protocol Http `
    -FrontendIPConfiguration $WEFrontendIpConfig `
    -FrontendPort $WEFrontendPort


$WERoutingRule = New-AzApplicationGatewayRequestRoutingRule `
    -Name " routingRule01" `
    -RuleType Basic `
    -HttpListener $WEHttpListener `
    -BackendAddressPool $WEBackendPool `
    -BackendHttpSettings $WEBackendHttpSettings

; 
$WESku = New-AzApplicationGatewaySku `
    -Name $WESkuName `
    -Tier $WETier `
    -Capacity $WECapacity


Write-WELog " `nCreating Application Gateway (this may take 10-15 minutes)..." " INFO" ; 
$WEAppGateway = New-AzApplicationGateway `
    -Name $WEGatewayName `
    -ResourceGroupName $WEResourceGroupName `
    -Location $WELocation `
    -GatewayIpConfiguration $WEGatewayIpConfig `
    -FrontendIpConfiguration $WEFrontendIpConfig `
    -FrontendPort $WEFrontendPort `
    -BackendAddressPool $WEBackendPool `
    -BackendHttpSetting $WEBackendHttpSettings `
    -HttpListener $WEHttpListener `
    -RequestRoutingRule $WERoutingRule `
    -Sku $WESku

Write-WELog " `nApplication Gateway $WEGatewayName provisioned successfully" " INFO"
Write-WELog " Public IP: $($WEPublicIp.IpAddress)" " INFO"
Write-WELog " Provisioning State: $($WEAppGateway.ProvisioningState)" " INFO"

Write-WELog " `nApplication Gateway provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
