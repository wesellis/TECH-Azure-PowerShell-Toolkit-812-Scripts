#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Full Ms Version

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
    We Enhanced Full Ms Version

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes


  https://docs.microsoft.com/en-us/azure/vpn-gateway/create-routebased-vpn-gateway-powershell


New-AzResourceGroup -Name TestRG1 -Location EastUS


$params = @{
    ErrorAction = "Stop"
    AddressPrefix = "10.1.0.0/16"
    ResourceGroupName = "TestRG1"
    Name = "VNet1"
    Location = "EastUS"
}
$virtualNetwork @params


  $params = @{
      AddressPrefix = "10.1.0.0/24"
      VirtualNetwork = $virtualNetwork
      Name = "Frontend"
  }
  $subnetConfig @params


  $virtualNetwork | Set-AzVirtualNetwork -ErrorAction Stop


  $vnet = Get-AzVirtualNetwork -ResourceGroupName TestRG1 -Name VNet1


  Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.1.255.0/27 -VirtualNetwork $vnet


  $vnet | Set-AzVirtualNetwork -ErrorAction Stop


  $gwpip= New-AzPublicIpAddress -Name VNet1GWIP -ResourceGroupName TestRG1 -Location 'East US' -AllocationMethod Dynamic

  $vnet = Get-AzVirtualNetwork -Name VNet1 -ResourceGroupName TestRG1
 ;  $subnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
 ;  $gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id


  New-AzVirtualNetworkGateway -Name "VNet1GW" -ResourceGroupName "TestRG1"
-Location -GatewayType "Vpn" -IpConfigurations $gwipconfig
-VpnType RouteBased -GatewaySku VpnGw1


Get-AzVirtualNetworkGateway -Name Vnet1GW -ResourceGroup TestRG1



Get-AzPublicIpAddress -Name VNet1GWIP -ResourceGroupName TestRG1



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
