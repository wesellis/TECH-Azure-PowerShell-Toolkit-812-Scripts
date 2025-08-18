<#
.SYNOPSIS
    We Enhanced Invoke Azvmosdisk

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

function WE-FunctionName {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-FunctionName {
    #Region func Set-AzVMOSDisk
    #Setting the VM OS Disk to the VM
    $setAzVMOSDiskSplat = @{
        VM           = $WEVirtualMachine
        Name         = $WEOSDiskName
        # VhdUri = $WEOSDiskUri
        # SourceImageUri = $WESourceImageUri
        Caching      = $WEOSDiskCaching
        CreateOption = $WEOSCreateOption
        # Windows = $true
        DiskSizeInGB = '128'
    }
   ;  $WEVirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat
    #endRegion func Set-AzVMOSDisk

    
}




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================