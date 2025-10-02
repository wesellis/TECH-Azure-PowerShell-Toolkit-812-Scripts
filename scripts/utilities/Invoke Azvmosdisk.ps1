#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Invoke Azvmosdisk

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function FunctionName {
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function FunctionName {
$SetAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        DiskSizeInGB = '128'
    }
$VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat`n}
