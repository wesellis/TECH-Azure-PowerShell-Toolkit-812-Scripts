#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    14.3.1 Get virtualnetwork
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
    General notes
        You do not need to create a new VNET as Bastion deployment is per virtual network, not per subscription/account or virtual machine. So ensure you place the Bastion in your existing VNET
$getAzVirtualNetworkSplat = @{
    Name = 'ProductionVNET'
}
$vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat


