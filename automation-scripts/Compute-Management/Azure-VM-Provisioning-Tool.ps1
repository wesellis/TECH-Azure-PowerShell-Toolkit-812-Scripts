#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
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

#region Functions

Write-Information "Provisioning Virtual Machine: $VmName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "VM Size: $VmSize"

# Create VM configuration
$VmConfig = New-AzVMConfig -VMName $VmName -VMSize $VmSize

# Set operating system
$VmConfig = Set-AzVMOperatingSystem -VM $VmConfig -Windows -ComputerName $VmName -Credential (New-Object -ErrorAction Stop PSCredential($AdminUsername, $AdminPassword))

# Set source image
$VmConfig = Set-AzVMSourceImage -VM $VmConfig -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $ImageSku -Version "latest"

# Create the VM
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VmConfig

Write-Information "Virtual Machine $VmName provisioned successfully"


#endregion
