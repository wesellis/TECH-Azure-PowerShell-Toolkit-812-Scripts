<#
.SYNOPSIS
    New Azpublicipaddress

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$newAzPublicIpAddressSplat = @{
    ResourceGroupName = "FGC_Prod_Bastion_RG"
    Name = "FGC_Prod_Bastion_PublicIP"
    Location = " canadacentral"
    AllocationMethod = 'Static'
    Sku = 'Standard'
}
$publicip = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat\n