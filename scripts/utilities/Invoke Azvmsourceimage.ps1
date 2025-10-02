#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Invoke Azvmsourceimage

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVMSourceImage {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVMSourceImage {
$SetAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        publisherName = "MicrosoftWindowsDesktop"
        offer         = " office-365"
        Skus          = " 20h2-evd-o365pp"
        version       = " latest"
    }
$VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat`n}
