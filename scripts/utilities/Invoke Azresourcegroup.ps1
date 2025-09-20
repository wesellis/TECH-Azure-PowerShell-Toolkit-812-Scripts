#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Azresourcegroup

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzResourceGroup {
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzResourceGroup {
    #region func-New-AzResourceGroup -ErrorAction Stop
    #Creating the Resource Group Name
$newAzResourceGroupSplat = @{
        Name     = $ResourceGroupName
        Location = $LocationName
        Tag      = $Tags
    }
    New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
    #endregion func New-AzResourceGroup -ErrorAction Stop
}


