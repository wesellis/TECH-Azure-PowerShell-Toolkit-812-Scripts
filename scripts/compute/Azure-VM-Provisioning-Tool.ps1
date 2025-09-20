#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Provision Azure Virtual Machine

.DESCRIPTION
    Create and provision a new Azure Virtual Machine with specified configuration


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

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
Write-Host "Provisioning Virtual Machine: $VmName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "VM Size: $VmSize"
# Create VM configuration
$VmConfig = New-AzVMConfig -VMName $VmName -VMSize $VmSize
# Set operating system
$vmoperatingsystemSplat = @{
    VM = $VmConfig
    ComputerName = $VmName
    Credential = New-Object PSCredential($AdminUsername, $AdminPassword)
}
Set-AzVMOperatingSystem @vmoperatingsystemSplat
# Set source image
$vmsourceimageSplat = @{
    VM = $VmConfig
    PublisherName = $ImagePublisher
    Offer = $ImageOffer
    Skus = $ImageSku
    Version = "latest"
}
Set-AzVMSourceImage @vmsourceimageSplat
# Create the VM
$vmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    VM = $VmConfig
}
New-AzVM @vmSplat
Write-Host "Virtual Machine $VmName provisioned successfully"

