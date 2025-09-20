#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Invoke Azvm

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVM {
}
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVM {
    #region func-New-AzVM -ErrorAction Stop
    #Creating the VM
$newAzVMSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        VM                = $VirtualMachine
        Verbose           = $true
        Tag               = $Tags
    }
    New-AzVM -ErrorAction Stop @newAzVMSplat
    #endRegion func New-AzVM -ErrorAction Stop
}


