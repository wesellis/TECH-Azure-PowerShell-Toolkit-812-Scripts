<#
.SYNOPSIS
    New Aznetworksecuritygroup

.DESCRIPTION
    New Aznetworksecuritygroup operation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$newAzNetworkSecurityRuleConfigSplat = @{
    Name = 'rdp-rule'
    Description = "Allow RDP"
    Access = 'Allow'
    Protocol = 'Tcp'
    Direction = 'Inbound'
    Priority = 100
    SourceAddressPrefix = 'Internet'
    SourcePortRange = '*'
    DestinationAddressPrefix = '*'
    DestinationPortRange = 3389
}
$rule1 = New-AzNetworkSecurityRuleConfig -ErrorAction Stop @newAzNetworkSecurityRuleConfigSplat
$newAzNetworkSecurityRuleConfigSplat = @{
    Name = 'web-rule'
    Description = "Allow HTTP"
    Access = 'Allow'
    Protocol = 'Tcp'
    Direction = 'Outbound'
    Priority = 101
    SourceAddressPrefix = 'Internet'
    SourcePortRange = '*'
    DestinationAddressPrefix = '*'
    DestinationPortRange = 80
}
$rule2 = New-AzNetworkSecurityRuleConfig -ErrorAction Stop @newAzNetworkSecurityRuleConfigSplat
$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = 'InspireAV_UniFi_RG'
    Location = 'CanadaCentral'
    Name = "NSG-FrontEnd"
    SecurityRules = $rule1, $rule2
}
$nsg = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat\n