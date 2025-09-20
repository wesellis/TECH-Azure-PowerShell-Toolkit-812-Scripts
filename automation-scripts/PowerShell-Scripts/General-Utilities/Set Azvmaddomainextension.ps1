#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Set Azvmaddomainextension

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$DomainName = "Canadacomputing.ca"
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$DomainName = "Canadacomputing.ca"
$VMName = "TrueSky1"
$ResourceGroupName = "CCI_TrueSky1_RG"
$setAzVMADDomainExtensionSplat = @{
    DomainName = $DomainName
    # Credential = $credential
    ResourceGroupName = $ResourceGroupName
    VMName = $VMName
    # OUPath = $OU
    JoinOption = 0x00000003
    Restart = $true
    Verbose = $true
}
Set-AzVMADDomainExtension -ErrorAction Stop @setAzVMADDomainExtensionSplat
$setAzVMADDomainExtensionSplat = @{
    DomainName = $DomainName
    VMName = $VMName
    Credential = $credential
    ResourceGroupName = $ResourceGroupName
    JoinOption = 0x00000001
    Restart = $true
    Verbose = $true
}
Set-AzVMADDomainExtension -ErrorAction Stop @setAzVMADDomainExtensionSplat
$setAzVMADDomainExtensionSplat = @{
    # publisher = "Microsoft.Azure.ActiveDirectory"
    # type = "AADLoginForWindows"
    typeHandlerVersion = " 0.3"
    # autoUpgradeMinorVersion = $true
}
Set-AzVMADDomainExtension -ErrorAction Stop @setAzVMADDomainExtensionSplat
$setAzVMADDomainExtensionSplat = @{
    DomainName = $domainToJoin
    Credential = $WvdDJCredUPN
    ResourceGroupName = $ResourceGroup
    VMName = $vmName
    # OUPath = $OU
    JoinOption = 0x00000003
    Restart = $true
    Verbose = $true
}
Set-AzVMADDomainExtension -ErrorAction Stop @setAzVMADDomainExtensionSplat\n

