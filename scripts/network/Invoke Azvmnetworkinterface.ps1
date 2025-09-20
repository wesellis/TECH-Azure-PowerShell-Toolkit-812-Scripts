#Requires -Version 7.0

<#`n.SYNOPSIS
    Invoke Azvmnetworkinterface

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVMNetworkInterface {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVMNetworkInterface {
    #Region func Add-AzVMNetworkInterface
    #Adding the NIC to the VM
$addAzVMNetworkInterfaceSplat = @{
        VM = $VirtualMachine
        Id = $NIC.Id
    }
$VirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
    #endRegion func Add-AzVMNetworkInterface
}
