<#
.SYNOPSIS
    We Enhanced Invoke Azresourcegroup

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

function WE-Invoke-AzResourceGroup {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-AzResourceGroup {
    #Region func New-AzResourceGroup
    #Creating the Resource Group Name
   ;  $newAzResourceGroupSplat = @{
        Name     = $WEResourceGroupName
        Location = $WELocationName
        Tag      = $WETags
    }


    New-AzResourceGroup @newAzResourceGroupSplat
    #endregion func New-AzResourceGroup
    
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================