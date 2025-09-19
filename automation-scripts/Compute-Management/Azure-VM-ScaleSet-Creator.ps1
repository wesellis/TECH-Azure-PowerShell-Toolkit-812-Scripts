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
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ScaleSetName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$VmSize,
    
    [Parameter(Mandatory=$false)]
    [int]$InstanceCount = 2
)

#region Functions

Write-Information "Creating VM Scale Set: $ScaleSetName"

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

Write-Information " VM Scale Set created successfully:"
Write-Information "  Name: $($Vmss.Name)"
Write-Information "  Location: $($Vmss.Location)"
Write-Information "  VM Size: $VmSize"
Write-Information "  Instance Count: $InstanceCount"


#endregion
