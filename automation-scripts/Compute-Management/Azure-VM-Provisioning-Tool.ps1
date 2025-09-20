<#
.SYNOPSIS
    Provision Azure Virtual Machine

.DESCRIPTION
    Create and provision a new Azure Virtual Machine with specified configuration
    Author: Wes Ellis (wes@wesellis.com)#>
param (
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
$VmConfig = Set-AzVMOperatingSystem -VM $VmConfig -Windows -ComputerName $VmName -Credential (New-Object PSCredential($AdminUsername, $AdminPassword))
# Set source image
$VmConfig = Set-AzVMSourceImage -VM $VmConfig -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $ImageSku -Version "latest"
# Create the VM
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VmConfig
Write-Host "Virtual Machine $VmName provisioned successfully"

