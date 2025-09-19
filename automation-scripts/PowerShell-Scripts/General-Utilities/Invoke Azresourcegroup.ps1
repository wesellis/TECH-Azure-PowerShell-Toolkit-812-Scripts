#Requires -Version 7.0
#Requires -Module Az.Resources

<#
.SYNOPSIS
    Invoke Azresourcegroup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Invoke Azresourcegroup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function WE-Invoke-AzResourceGroup {



$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-AzResourceGroup {
    #Region func New-AzResourceGroup -ErrorAction Stop
    #Creating the Resource Group Name
   ;  $newAzResourceGroupSplat = @{
        Name     = $WEResourceGroupName
        Location = $WELocationName
        Tag      = $WETags
    }


    New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
    #endregion func New-AzResourceGroup -ErrorAction Stop
    
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

