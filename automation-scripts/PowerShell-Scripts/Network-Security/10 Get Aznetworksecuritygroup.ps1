<#
.SYNOPSIS
    Get networksecuritygroup

.DESCRIPTION
    Get networksecuritygroup operation
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
    General notes
Get-AzNetworkSecurityGroup -ErrorAction Stop | Select-Object -Property Name
Get-AzNetworkSecurityGroup -Name 'FAX1-nsg' -ResourceGroupName "FAX1_GROUP"

