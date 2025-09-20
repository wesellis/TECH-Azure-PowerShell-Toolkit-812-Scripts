<#
.SYNOPSIS
    Invoke Aznetworksecurityruleconfig

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzNetworkSecurityRuleConfig {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzNetworkSecurityRuleConfig {
    #Region func New-AzNetworkSecurityRuleConfig;
$newAzNetworkSecurityRuleConfigSplat = @{
    # Name = 'rdp-rule'
    Name                                = 'RDP-rule'
    # Description = "Allow RDP"
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
$rule1 = New-AzNetworkSecurityRuleConfig -ErrorAction Stop @newAzNetworkSecurityRuleConfigSplat
}\n