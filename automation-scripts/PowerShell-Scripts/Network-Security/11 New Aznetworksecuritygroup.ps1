<#
.SYNOPSIS
    11 New Aznetworksecuritygroup

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
    We Enhanced 11 New Aznetworksecuritygroup

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
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$newAzNetworkSecurityRuleConfigSplat = @{
    Name = 'rdp-rule'
    Description = " Allow RDP"
    Access = 'Allow'
    Protocol = 'Tcp'
    Direction = 'Inbound'
    Priority = 100
    SourceAddressPrefix = 'Internet'
    SourcePortRange = '*'
    DestinationAddressPrefix = '*'
    DestinationPortRange = 3389
}

$rule1 = New-AzNetworkSecurityRuleConfig @newAzNetworkSecurityRuleConfigSplat



$newAzNetworkSecurityRuleConfigSplat = @{
    Name = 'web-rule'
    Description = " Allow HTTP"
    Access = 'Allow'
    Protocol = 'Tcp'
    Direction = 'Outbound'
    Priority = 101
    SourceAddressPrefix = 'Internet'
    SourcePortRange = '*'
    DestinationAddressPrefix = '*'
    DestinationPortRange = 80
}
$rule2 = New-AzNetworkSecurityRuleConfig @newAzNetworkSecurityRuleConfigSplat

; 
$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = 'InspireAV_UniFi_RG'
    Location = 'CanadaCentral'
    Name = " NSG-FrontEnd"
    SecurityRules = $rule1, $rule2
}
; 
$nsg = New-AzNetworkSecurityGroup @newAzNetworkSecurityGroupSplat


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================