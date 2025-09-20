#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Get vmimagepublisher

.DESCRIPTION
    Get vmimagepublisher operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    PublisherName  Location      Id
-------------  --------      --
Canonical      CanadaCentral /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publ...
canonical-test CanadaCentral /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/Providers/Microsoft.Compute/Locations/CanadaCentral/Publ...
    General notes
Get-AzVMImagePublisher -Location 'CanadaCentral' | Select-Object -First 1
Get-AzVMImagePublisher -Location 'CanadaCentral' | Select-Object -Property PublisherName
Get-AzVMImagePublisher -Location 'CanadaCentral' | Where-Object {$_.PublisherName -like '*Canonical*'}
Get-AzVMImagePublisher -Location 'CanadaCentral' | Where-Object {$_.PublisherName -like '*OpenLogic*'}
Get-AzVMImagePublisher -Location 'CanadaCentral' | Where-Object {$_.PublisherName -like 'MicrosoftWindowsDesktop'}

