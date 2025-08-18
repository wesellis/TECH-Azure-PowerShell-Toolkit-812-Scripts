<#
.SYNOPSIS
    14.3 New Azvirtualnetwork

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
    We Enhanced 14.3 New Azvirtualnetwork

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
.NOTES
    General notes
    Create a virtual network

    You do not need to create a new VNET as Bastion deployment is per virtual network, not per subscription/account or virtual machine. So ensure you place the Bastion in your existing VNET

    This article shows you how to create an Azure Bastion host using PowerShell. Once you provision the Azure Bastion service in your virtual network, the seamless RDP/SSH experience is available to all of the VMs in the same virtual network. Azure Bastion deployment is per virtual network, not per subscription/account or virtual machine.




    Create a virtual network and an Azure Bastion subnet. You must create the Azure Bastion subnet using the name value AzureBastionSubnet. This value lets Azure know which subnet to deploy the Bastion resources to. This is different than a Gateway subnet. You must use a subnet of at least /27 or larger subnet (/27, /26, and so on). Create the AzureBastionSubnet without any route tables or delegations. If you use Network Security Groups on the AzureBastionSubnet, refer to the Work with NSGs article.


; 
$newAzVirtualNetworkSplat = @{
    Name = " myVnet"
    ResourceGroupName = " myBastionRG"
    Location = " westeurope"
    AddressPrefix = '10.0.0.0/16'
    Subnet = $subnet
}
; 
$vnet = New-AzVirtualNetwork -ErrorAction Stop @newAzVirtualNetworkSplat





# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================