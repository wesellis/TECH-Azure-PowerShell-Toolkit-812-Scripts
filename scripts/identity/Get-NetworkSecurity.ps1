#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Check network security configuration

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
Audit NSG rules and subnet configurations
.PARAMETER ResourceGroup
Resource group to check
.EXAMPLE
.\Get-NetworkSecurity.ps1
.EXAMPLE
.\Get-NetworkSecurity.ps1 -ResourceGroup rg-prod
[CmdletBinding()]
$ErrorActionPreference = 'Stop'

[string]$ResourceGroup)
$nsgs = if ($ResourceGroup) { Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup } else { Get-AzNetworkSecurityGroup }
foreach ($nsg in $nsgs) {
    $OpenRules = $nsg.SecurityRules | Where-Object {
        $_.SourceAddressPrefix -eq "*" -and
        $_.DestinationPortRange -contains "*" -and
        $_.Access -eq "Allow"
    }
    if ($OpenRules) {
        [PSCustomObject]@{
            NSG = $nsg.Name
            ResourceGroup = $nsg.ResourceGroupName
            OpenRules = $OpenRules.Count
            Issue = "Wide open inbound rules"
        }
    }
}
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
`n}
