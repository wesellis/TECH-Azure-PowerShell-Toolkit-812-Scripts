<#
.SYNOPSIS
    Invoke Azvmconfig

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
    We Enhanced Invoke Azvmconfig

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function WE-Invoke-AzVMConfig {
}


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-AzVMConfig {
 
    #Region func New-AzVMConfig -ErrorAction Stop
    #Creating the VM Config Object for the VM
   ;  $newAzVMConfigSplat = @{
        VMName       = $WEVMName
        VMSize       = $WEVMSize
        Tags         = $WETags
        IdentityType = 'SystemAssigned'
    }
   ;  $WEVirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
    #endRegion func New-AzVMConfig -ErrorAction Stop
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================