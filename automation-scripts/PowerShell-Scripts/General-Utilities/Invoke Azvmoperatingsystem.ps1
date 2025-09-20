<#
.SYNOPSIS
    Invoke Azvmoperatingsystem

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVMOperatingSystem {
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVMOperatingSystem {
    #Region func Set-AzVMOperatingSystem -ErrorAction Stop
    #Creating the OS Object for the VM
$setAzVMOperatingSystemSplat = @{
        VM               = $VirtualMachine
        Windows          = $true
        # Linux        = $true
        ComputerName     = $ComputerName
        Credential       = $Credential
        ProvisionVMAgent = $true
        # EnableAutoUpdate = $true
    }
$VirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
    #endRegion func Set-AzVMOperatingSystem -ErrorAction Stop
}\n