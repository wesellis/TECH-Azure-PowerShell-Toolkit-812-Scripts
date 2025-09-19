#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    14.2.1 Get Azvirtualnetworksubnetconfig

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
    We Enhanced 14.2.1 Get Azvirtualnetworksubnetconfig

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

    
Name                              : PublicFacingSubnet
Id                                : /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/Microsoft 
                                    .Network/virtualNetworks/ProductionVNET/subnets/PublicFacingSubnet
Etag                              : W/" e7215fa5-0989-4683-9c6b-fc8bbbac5142"
ProvisioningState                 : Succeeded
AddressPrefix                     : {10.0.0.0/24}
IpConfigurations                  : [
                                      {
                                        " Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/provider 
                                    s/Microsoft.Network/networkInterfaces/ProdFortiGate-Nic0-jml4cp2jxyius/ipConfigurations/ipconfig1"    
                                      }
                                    ]
ResourceNavigationLinks           : []
ServiceAssociationLinks           : []
NetworkSecurityGroup              : null
RouteTable                        : {
                                      " DisableBgpRoutePropagation" : false,
                                      " Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/ 
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
                                        " Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/provider 
                                    s/Microsoft.Network/networkInterfaces/ProdFortiGate-Nic1-jml4cp2jxyius/ipConfigurations/ipconfig1"    
                                      }
                                    ]
ResourceNavigationLinks           : []
ServiceAssociationLinks           : []
NetworkSecurityGroup              : null
RouteTable                        : {
                                      " DisableBgpRoutePropagation" : false,
                                      " Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/ 
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

.NOTES
    General notes

; 
$getAzVirtualNetworkSplat = @{
    Name = 'ProductionVNET'
}
; 
$vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat


Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet | Select-Object -Property AddressPrefix,Name
Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'InsideSubnet' | Select-Object -Property AddressPrefix,Name


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
