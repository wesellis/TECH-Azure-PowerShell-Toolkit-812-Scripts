#Requires -Version 7.0
#Requires -Module Az.Resources

<#
.SYNOPSIS
    Invoke Azvmosdisk

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
    We Enhanced Invoke Azvmosdisk

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
function WE-FunctionName {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-FunctionName {
    #Region func Set-AzVMOSDisk -ErrorAction Stop
    #Setting the VM OS Disk to the VM
   ;  $setAzVMOSDiskSplat = @{
        VM           = $WEVirtualMachine
        Name         = $WEOSDiskName
        # VhdUri = $WEOSDiskUri
        # SourceImageUri = $WESourceImageUri
        Caching      = $WEOSDiskCaching
        CreateOption = $WEOSCreateOption
        # Windows = $true
        DiskSizeInGB = '128'
    }
   ;  $WEVirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
    #endRegion func Set-AzVMOSDisk -ErrorAction Stop

    
}




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

