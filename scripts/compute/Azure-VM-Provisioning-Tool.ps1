#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Provision Azure Virtual Machine

.DESCRIPTION
    Create and provision a new Azure Virtual Machine with specified configuration


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$VmName,
    [string]$Location,
    [string]$VmSize = "Standard_B2s",
    [string]$AdminUsername,
    [securestring]$AdminPassword,
    [string]$ImagePublisher = "MicrosoftWindowsServer",
    [string]$ImageOffer = "WindowsServer",
    [string]$ImageSku = "2022-Datacenter"
)
Write-Output "Provisioning Virtual Machine: $VmName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "VM Size: $VmSize"
$VmConfig = New-AzVMConfig -VMName $VmName -VMSize $VmSize
$VmoperatingsystemSplat = @{
    VM = $VmConfig
    ComputerName = $VmName
    Credential = New-Object PSCredential($AdminUsername, $AdminPassword)
}
Set-AzVMOperatingSystem @vmoperatingsystemSplat
$VmsourceimageSplat = @{
    VM = $VmConfig
    PublisherName = $ImagePublisher
    Offer = $ImageOffer
    Skus = $ImageSku
    Version = "latest"
}
Set-AzVMSourceImage @vmsourceimageSplat
$VmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    VM = $VmConfig
}
New-AzVM @vmSplat
Write-Output "Virtual Machine $VmName provisioned successfully"



