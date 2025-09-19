#Requires -Version 7.0
#Requires -Module Az.Resources

<#
.SYNOPSIS
    Invoke Azvmoperatingsystem

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
    We Enhanced Invoke Azvmoperatingsystem

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
function WE-Invoke-AzVMOperatingSystem {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-AzVMOperatingSystem {

    #Region func Set-AzVMOperatingSystem -ErrorAction Stop
    #Creating the OS Object for the VM
   ;  $setAzVMOperatingSystemSplat = @{
        VM               = $WEVirtualMachine
        Windows          = $true
        # Linux        = $true
        ComputerName     = $WEComputerName
        Credential       = $WECredential
        ProvisionVMAgent = $true
        # EnableAutoUpdate = $true
    
    }
   ;  $WEVirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
    #endRegion func Set-AzVMOperatingSystem -ErrorAction Stop 

    
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

