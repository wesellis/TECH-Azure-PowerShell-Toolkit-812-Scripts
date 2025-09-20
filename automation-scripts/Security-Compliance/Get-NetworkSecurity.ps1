#Requires -Version 7.0
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Check network security configuration

.DESCRIPTION
Audit NSG rules and subnet configurations
.PARAMETER ResourceGroup
Resource group to check
.EXAMPLE
.\Get-NetworkSecurity.ps1
.EXAMPLE
.\Get-NetworkSecurity.ps1 -ResourceGroup rg-prod
#>
[CmdletBinding()]
[string]$ResourceGroup)
# Get NSGs
$nsgs = if ($ResourceGroup) { Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup } else { Get-AzNetworkSecurityGroup }
foreach ($nsg in $nsgs) {
    $openRules = $nsg.SecurityRules | Where-Object {
        $_.SourceAddressPrefix -eq "*" -and
        $_.DestinationPortRange -contains "*" -and
        $_.Access -eq "Allow"
    }
    if ($openRules) {
        [PSCustomObject]@{
            NSG = $nsg.Name
            ResourceGroup = $nsg.ResourceGroupName
            OpenRules = $openRules.Count
            Issue = "Wide open inbound rules"
        }
    }
}
# Check for VNets without NSGs
$vnets = if ($ResourceGroup) { Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup } else { Get-AzVirtualNetwork }
foreach ($vnet in $vnets) {
    foreach ($subnet in $vnet.Subnets) {
        if (-not $subnet.NetworkSecurityGroup) {
            [PSCustomObject]@{
                VNet = $vnet.Name
                Subnet = $subnet.Name
                ResourceGroup = $vnet.ResourceGroupName
                Issue = "No NSG assigned"
            }
        }
    }
}\n

