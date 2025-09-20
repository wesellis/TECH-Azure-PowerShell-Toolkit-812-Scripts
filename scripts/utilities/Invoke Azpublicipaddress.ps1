#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Azpublicipaddress

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzPublicIpAddress {
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzPublicIpAddress {
 #region func-New-AzPublicIpAddress -ErrorAction Stop
$newAzPublicIpAddressSplat = @{
    Name              = $PublicIPAddressName
    DomainNameLabel   = $DNSNameLabel
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    # AllocationMethod  = 'Dynamic'
    AllocationMethod  = 'Static'
    # IpTag             = $ipTag
    Tag               = $Tags
};
$PIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat
}


