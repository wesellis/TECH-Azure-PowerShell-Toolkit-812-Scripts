<#
.SYNOPSIS
    New Azresourcegroup

.DESCRIPTION
    New Azresourcegroup operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
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
New-AzResourceGroup -Name 'FGCHealth_Prod-PAS1_RG' -Location "CanadaCentral"

