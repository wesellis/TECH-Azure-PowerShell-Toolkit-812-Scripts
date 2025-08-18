<#
.SYNOPSIS
    Invoke Azvm

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
    We Enhanced Invoke Azvm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function WE-Invoke-AzVM {
}


$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-AzVM {
    
    

    #Region func New-AzVM
    #Creating the VM
   ;  $newAzVMSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        VM                = $WEVirtualMachine
        Verbose           = $true
        Tag               = $WETags
    }
    New-AzVM @newAzVMSplat
    #endRegion func New-AzVM
    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================