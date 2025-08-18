<#
.SYNOPSIS
    Invoke Azvmsourceimage

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
    We Enhanced Invoke Azvmsourceimage

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function WE-Invoke-AzVMSourceImage {
}


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-AzVMSourceImage {
    #Region func Set-AzVMSourceImage 
   ;  $setAzVMSourceImageSplat = @{
        VM            = $WEVirtualMachine
        # PublisherName = " Canonical"
        # Offer         = " 0001-com-ubuntu-server-focal"
        # Skus          = " 20_04-lts-gen2"
        # Version       = " latest"
        publisherName = " MicrosoftWindowsDesktop"
        offer         = " office-365"
        Skus          = " 20h2-evd-o365pp"
        version       = " latest"


        # publisherName = " MicrosoftWindowsServer"
        # offer         = " WindowsServer"
        # Skus          = " 2019-datacenter-gensecond"
        # version       = " latest"



        # Caching = 'ReadWrite'
    }


   ;  $WEVirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat
    #endRegion func Set-AzVMSourceImage
    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================