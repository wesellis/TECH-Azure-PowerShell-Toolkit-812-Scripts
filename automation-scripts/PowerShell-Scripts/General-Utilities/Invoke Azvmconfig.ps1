<#
.SYNOPSIS
    Invoke Azvmconfig

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVMConfig {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVMConfig {
    #Region func New-AzVMConfig -ErrorAction Stop
    #Creating the VM Config Object for the VM
$newAzVMConfigSplat = @{
        VMName       = $VMName
        VMSize       = $VMSize
        Tags         = $Tags
        IdentityType = 'SystemAssigned'
    }
$VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
    #endRegion func New-AzVMConfig -ErrorAction Stop
}

