<#
.SYNOPSIS
    We Enhanced 5.1 Get Azvmextensions

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


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)


    Id               : /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publishe
                   rs/Microsoft.Azure.ActiveDirectory/ArtifactTypes/VMExtension/Types/AADLoginForWindows/Versions/0.3.0.0
Location         : CanadaCentral
PublisherName    : Microsoft.Azure.ActiveDirectory
Type             : AADLoginForWindows
Version          : 0.3.0.0
FilterExpression :

Id               : /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publishe 
                   rs/Microsoft.Azure.ActiveDirectory/ArtifactTypes/VMExtension/Types/AADLoginForWindows/Versions/0.3.1.0
Location         : CanadaCentral
PublisherName    : Microsoft.Azure.ActiveDirectory
Type             : AADLoginForWindows
Version          : 0.3.1.0
FilterExpression :

Id               : /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publishe 
                   rs/Microsoft.Azure.ActiveDirectory/ArtifactTypes/VMExtension/Types/AADLoginForWindows/Versions/0.4.1.0
Location         : CanadaCentral
PublisherName    : Microsoft.Azure.ActiveDirectory
Type             : AADLoginForWindows
Version          : 0.4.1.0
FilterExpression :

Id               : /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publishe 
                   rs/Microsoft.Azure.ActiveDirectory/ArtifactTypes/VMExtension/Types/AADLoginForWindows/Versions/0.4.1.1
Location         : CanadaCentral
PublisherName    : Microsoft.Azure.ActiveDirectory
Type             : AADLoginForWindows
Version          : 0.4.1.1
FilterExpression :

Id               : /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publishe 
                   rs/Microsoft.Azure.ActiveDirectory/ArtifactTypes/VMExtension/Types/AADLoginForWindows/Versions/1.0.0.0
Location         : CanadaCentral
PublisherName    : Microsoft.Azure.ActiveDirectory
Type             : AADLoginForWindows
Version          : 1.0.0.0
FilterExpression :

Id               : /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publishe 
                   rs/Microsoft.Azure.ActiveDirectory/ArtifactTypes/VMExtension/Types/AADLoginForWindows/Versions/1.0.0.1
Location         : CanadaCentral
PublisherName    : Microsoft.Azure.ActiveDirectory
Type             : AADLoginForWindows
Version          : 1.0.0.1
FilterExpression :

.NOTES
    General notes



Get-AzVmImagePublisher -Location " CanadaCentral" | Get-AzVMExtensionImageType | Get-AzVMExtensionImage | Select-Object Type, Version


$getAzVMExtensionImageSplat = @{
    Location = " CanadaCentral"
    PublisherName = 'Microsoft.Azure.ActiveDirectory'
    Type = " AADLoginForWindows"
}

Get-AzVMExtensionImage @getAzVMExtensionImageSplat | Select-Object *




$WEVMName = " TrueSky1"

$WEResourceGroupName = " CCI_TrueSky1_RG"
; 
$getAzVMSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Name = $WEVMName
    Status = $true
}

Get-AzVM @getAzVMSplat | clip




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================