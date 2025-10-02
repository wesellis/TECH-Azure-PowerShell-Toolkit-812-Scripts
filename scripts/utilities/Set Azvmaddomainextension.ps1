#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Set Azvmaddomainextension

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    ResourceGroupName = $ResourceGroupName
    VMName = $VMName
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
    typeHandlerVersion = " 0.3"
}
Set-AzVMADDomainExtension -ErrorAction Stop @setAzVMADDomainExtensionSplat
$setAzVMADDomainExtensionSplat = @{
    DomainName = $domainToJoin
    Credential = $WvdDJCredUPN
    ResourceGroupName = $ResourceGroup
    VMName = $vmName
    JoinOption = 0x00000003
    Restart = $true
    Verbose = $true
}
Set-AzVMADDomainExtension -ErrorAction Stop @setAzVMADDomainExtensionSplat


