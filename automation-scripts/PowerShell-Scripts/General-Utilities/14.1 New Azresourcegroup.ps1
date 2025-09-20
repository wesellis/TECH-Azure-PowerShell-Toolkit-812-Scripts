#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create resource group

.DESCRIPTION
    Create Azure resource group
    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
ResourceGroupName : InspireAV_UniFi_RG
Location          : canadacentral
ProvisioningState : Succeeded
Tags              :
ResourceId        : /subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/resourceGroups/InspireAV_UniFi_RG
    General notes
New-AzResourceGroup -Name 'FGC_Prod_Bastion_RG' -Location "CanadaCentral"

