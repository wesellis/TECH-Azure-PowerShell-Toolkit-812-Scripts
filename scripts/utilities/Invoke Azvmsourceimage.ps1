#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Invoke Azvmsourceimage

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVMSourceImage {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVMSourceImage {
    #region func-Set-AzVMSourceImage -ErrorAction Stop
$setAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        # PublisherName = "Canonical"
        # Offer         = " 0001-com-ubuntu-server-focal"
        # Skus          = " 20_04-lts-gen2"
        # Version       = " latest"
        publisherName = "MicrosoftWindowsDesktop"
        offer         = " office-365"
        Skus          = " 20h2-evd-o365pp"
        version       = " latest"
        # publisherName = "MicrosoftWindowsServer"
        # offer         = "WindowsServer"
        # Skus          = " 2019-datacenter-gensecond"
        # version       = " latest"
        # Caching = 'ReadWrite'
    }
$VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat
    #endRegion func Set-AzVMSourceImage -ErrorAction Stop
}


