<#
.SYNOPSIS
    We Enhanced Invoke Azvmoperatingsystem

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

function WE-Invoke-AzVMOperatingSystem {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-AzVMOperatingSystem {

    #Region func Set-AzVMOperatingSystem
    #Creating the OS Object for the VM
    $setAzVMOperatingSystemSplat = @{
        VM               = $WEVirtualMachine
        Windows          = $true
        # Linux        = $true
        ComputerName     = $WEComputerName
        Credential       = $WECredential
        ProvisionVMAgent = $true
        # EnableAutoUpdate = $true
    
    }
   ;  $WEVirtualMachine = Set-AzVMOperatingSystem @setAzVMOperatingSystemSplat
    #endRegion func Set-AzVMOperatingSystem 

    
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================