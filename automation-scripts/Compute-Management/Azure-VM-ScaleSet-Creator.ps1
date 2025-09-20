<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations\n    Author: Wes Ellis (wes@wesellis.com)\n#>
param (
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
Write-Host "Creating VM Scale Set: $ScaleSetName"
# Create scale set configuration
$params = @{
    ErrorAction = "Stop"
    SkuCapacity = $InstanceCount
    SkuName = $VmSize
    UpgradePolicyMode = "Manual"
    Location = $Location
}
$VmssConfig @params
# Add network profile
$params = @{
    CreatePublicIPAddress = $false
    IPConfigurationName = "internal"
    Primary = $true
    Name = "network-config"
    VirtualMachineScaleSet = $VmssConfig
}
$VmssConfig @params
# Set OS profile
$params = @{
    ComputerNamePrefix = "vmss"
    ErrorAction = "Stop"
    AdminUsername = "azureuser"
    VirtualMachineScaleSet = $VmssConfig
}
$VmssConfig @params
# Set storage profile
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
# Create the scale set
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $ScaleSetName
    VirtualMachineScaleSet = $VmssConfig
}
$Vmss @params
Write-Host "VM Scale Set created successfully:"
Write-Host "Name: $($Vmss.Name)"
Write-Host "Location: $($Vmss.Location)"
Write-Host "VM Size: $VmSize"
Write-Host "Instance Count: $InstanceCount"\n