#Requires -Version 7.4
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ScaleSetName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter(Mandatory)]
    [string]$VmSize,
    [Parameter()]
    [int]$InstanceCount = 2
)
Write-Output "Creating VM Scale Set: $ScaleSetName"
$params = @{
    ErrorAction = "Stop"
    SkuCapacity = $InstanceCount
    SkuName = $VmSize
    UpgradePolicyMode = "Manual"
    Location = $Location
}
$VmssConfig @params
$params = @{
    CreatePublicIPAddress = $false
    IPConfigurationName = "internal"
    Primary = $true
    Name = "network-config"
    VirtualMachineScaleSet = $VmssConfig
}
$VmssConfig @params
$params = @{
    ComputerNamePrefix = "vmss"
    ErrorAction = "Stop"
    AdminUsername = "azureuser"
    VirtualMachineScaleSet = $VmssConfig
}
$VmssConfig @params
$params = @{
    ImageReferenceOffer = "WindowsServer"
    ImageReferenceSku = "2022-Datacenter"
    ErrorAction = "Stop"
    OsDiskCreateOption = "FromImage"
    VirtualMachineScaleSet = $VmssConfig
    ImageReferenceVersion = "latest"
    ImageReferencePublisher = "MicrosoftWindowsServer"
}
$VmssConfig @params
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $ScaleSetName
    VirtualMachineScaleSet = $VmssConfig
}
$Vmss @params
Write-Output "VM Scale Set created successfully:"
Write-Output "Name: $($Vmss.Name)"
Write-Output "Location: $($Vmss.Location)"
Write-Output "VM Size: $VmSize"
Write-Output "Instance Count: $InstanceCount"



