#Requires -Version 7.0
#Requires -Module Az.Resources

<#
.SYNOPSIS
    Invoke Azvm

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
    We Enhanced Invoke Azvm

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
function WE-Invoke-AzVM {
}


$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-AzVM {
    
    

    #Region func New-AzVM -ErrorAction Stop
    #Creating the VM
   ;  $newAzVMSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        VM                = $WEVirtualMachine
        Verbose           = $true
        Tag               = $WETags
    }
    New-AzVM -ErrorAction Stop @newAzVMSplat
    #endRegion func New-AzVM -ErrorAction Stop
    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

