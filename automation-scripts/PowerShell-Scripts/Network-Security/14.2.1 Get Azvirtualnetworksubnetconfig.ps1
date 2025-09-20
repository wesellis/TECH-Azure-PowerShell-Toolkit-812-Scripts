<#
.SYNOPSIS
    14.2.1 Get virtualnetworksubnetconfig
.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
Name                              : PublicFacingSubnet
Id                                : /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/Microsoft
                                    .Network/virtualNetworks/ProductionVNET/subnets/PublicFacingSubnet
Etag                              : W/" e7215fa5-0989-4683-9c6b-fc8bbbac5142"
ProvisioningState                 : Succeeded
AddressPrefix                     : {10.0.0.0/24}
IpConfigurations                  : [
                                      {
                                        "Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/provider
                                    s/Microsoft.Network/networkInterfaces/ProdFortiGate-Nic0-jml4cp2jxyius/ipConfigurations/ipconfig1"
                                      }
                                    ]
ResourceNavigationLinks           : []
ServiceAssociationLinks           : []
NetworkSecurityGroup              : null
RouteTable                        : {
                                      "DisableBgpRoutePropagation" : false,
                                      "Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/
                                    Microsoft.Network/routeTables/ProdFortiGate-PublicFacingSubnet-routes-jml4cp2jxyius"
                                    }
NatGateway                        : null
ServiceEndpoints                  : []
ServiceEndpointPolicies           : []
PrivateEndpoints                  : []
PrivateEndpointNetworkPolicies    : Enabled
PrivateLinkServiceNetworkPolicies : Enabled
Name                              : InsideSubnet
Id                                : /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/Microsoft
                                    .Network/virtualNetworks/ProductionVNET/subnets/InsideSubnet
Etag                              : W/" e7215fa5-0989-4683-9c6b-fc8bbbac5142"
ProvisioningState                 : Succeeded
AddressPrefix                     : {10.0.1.0/24}
IpConfigurations                  : [
                                      {
                                        "Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/provider
                                    s/Microsoft.Network/networkInterfaces/ProdFortiGate-Nic1-jml4cp2jxyius/ipConfigurations/ipconfig1"
                                      }
                                    ]
ResourceNavigationLinks           : []
ServiceAssociationLinks           : []
NetworkSecurityGroup              : null
RouteTable                        : {
                                      "DisableBgpRoutePropagation" : false,
                                      "Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/
                                    Microsoft.Network/routeTables/ProdFortiGate-InsideSubnet-routes-jml4cp2jxyius"
                                    }
NatGateway                        : null
ServiceEndpoints                  : []
ServiceEndpointPolicies           : []
PrivateEndpoints                  : []
PrivateEndpointNetworkPolicies    : Enabled
PrivateLinkServiceNetworkPolicies : Enabled
AddressPrefix Name
------------- ----
{10.0.0.0/24} PublicFacingSubnet
{10.0.1.0/24} InsideSubnet
    General notes
$getAzVirtualNetworkSplat = @{
    Name = 'ProductionVNET'
}
$vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat
Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet | Select-Object -Property AddressPrefix,Name
Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'InsideSubnet' | Select-Object -Property AddressPrefix,Name

