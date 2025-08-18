<#
.SYNOPSIS
    Set Azvmaddomainextension

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
    We Enhanced Set Azvmaddomainextension

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEDomainName = "Canadacomputing.ca"



$WEErrorActionPreference = " Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$WEDomainName = " Canadacomputing.ca"
$WEVMName = " TrueSky1"

$WEResourceGroupName = " CCI_TrueSky1_RG"

$setAzVMADDomainExtensionSplat = @{
    DomainName = $WEDomainName
    # Credential = $credential
    ResourceGroupName = $WEResourceGroupName
    VMName = $WEVMName
    # OUPath = $WEOU
    JoinOption = 0x00000003
    Restart = $true
    Verbose = $true
}

Set-AzVMADDomainExtension @setAzVMADDomainExtensionSplat

 
$setAzVMADDomainExtensionSplat = @{
    DomainName = $WEDomainName
    VMName = $WEVMName
    Credential = $credential
    ResourceGroupName = $WEResourceGroupName
    JoinOption = 0x00000001
    Restart = $true
    Verbose = $true
}

Set-AzVMADDomainExtension @setAzVMADDomainExtensionSplat


; 
$setAzVMADDomainExtensionSplat = @{

    # publisher = " Microsoft.Azure.ActiveDirectory"
    # type = " AADLoginForWindows"
    typeHandlerVersion = " 0.3"
    # autoUpgradeMinorVersion = $true
}

Set-AzVMADDomainExtension @setAzVMADDomainExtensionSplat


; 
$setAzVMADDomainExtensionSplat = @{
    DomainName = $domainToJoin
    Credential = $WEWvdDJCredUPN
    ResourceGroupName = $WEResourceGroup
    VMName = $vmName
    # OUPath = $WEOU
    JoinOption = 0x00000003
    Restart = $true
    Verbose = $true
}

Set-AzVMADDomainExtension @setAzVMADDomainExtensionSplat

















    























# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================