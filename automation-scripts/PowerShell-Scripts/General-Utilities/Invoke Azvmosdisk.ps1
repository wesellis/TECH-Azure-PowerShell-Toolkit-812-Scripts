<#
.SYNOPSIS
    Invoke Azvmosdisk

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function FunctionName {
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function FunctionName {
    #Region func Set-AzVMOSDisk -ErrorAction Stop
    #Setting the VM OS Disk to the VM
$setAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        # VhdUri = $OSDiskUri
        # SourceImageUri = $SourceImageUri
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        # Windows = $true
        DiskSizeInGB = '128'
    }
$VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
    #endRegion func Set-AzVMOSDisk -ErrorAction Stop
}

