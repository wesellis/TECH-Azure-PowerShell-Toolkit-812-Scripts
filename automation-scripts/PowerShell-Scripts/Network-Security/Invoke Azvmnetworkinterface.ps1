#Requires -Version 7.0

<#
.SYNOPSIS
    Invoke Azvmnetworkinterface

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
    We Enhanced Invoke Azvmnetworkinterface

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
function WE-Invoke-AzVMNetworkInterface {
}


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-AzVMNetworkInterface {

    #Region func Add-AzVMNetworkInterface
    #Adding the NIC to the VM
   ;  $addAzVMNetworkInterfaceSplat = @{
        VM = $WEVirtualMachine
        Id = $WENIC.Id
    }
   ;  $WEVirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
    #endRegion func Add-AzVMNetworkInterface
    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

