#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Aznetworksecurityruleconfig

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzNetworkSecurityRuleConfig {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzNetworkSecurityRuleConfig {
$NewAzNetworkSecurityRuleConfigSplat = @{
    Name                                = 'RDP-rule'
    Description                         = 'Allow RDP'
    Access                              = 'Allow'
    Protocol                            = 'Tcp'
    Direction                           = 'Inbound'
    Priority                            = 100
    SourceAddressPrefix                 = $SourceAddressPrefixCIDR
    SourcePortRange                     = '*'
    DestinationPortRange                = '3389'
    DestinationApplicationSecurityGroup = $ASG
};
$rule1 = New-AzNetworkSecurityRuleConfig -ErrorAction Stop @newAzNetworkSecurityRuleConfigSplat`n}
