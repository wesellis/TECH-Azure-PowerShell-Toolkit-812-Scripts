# ============================================================================
# Script Name: Azure VM Scale Set Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Virtual Machine Scale Sets for auto-scaling
# ============================================================================

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

Write-Host "Creating VM Scale Set: $ScaleSetName"

# Create scale set configuration
$VmssConfig = New-AzVmssConfig `
    -Location $Location `
    -SkuCapacity $InstanceCount `
    -SkuName $VmSize `
    -UpgradePolicyMode "Manual"

# Add network profile
$VmssConfig = Add-AzVmssNetworkInterfaceConfiguration `
    -VirtualMachineScaleSet $VmssConfig `
    -Name "network-config" `
    -Primary $true `
    -IPConfigurationName "internal" `
    -CreatePublicIPAddress $false

# Set OS profile
$VmssConfig = Set-AzVmssOsProfile `
    -VirtualMachineScaleSet $VmssConfig `
    -ComputerNamePrefix "vmss" `
    -AdminUsername "azureuser"

# Set storage profile
$VmssConfig = Set-AzVmssStorageProfile `
    -VirtualMachineScaleSet $VmssConfig `
    -OsDiskCreateOption "FromImage" `
    -ImageReferencePublisher "MicrosoftWindowsServer" `
    -ImageReferenceOffer "WindowsServer" `
    -ImageReferenceSku "2022-Datacenter" `
    -ImageReferenceVersion "latest"

# Create the scale set
$Vmss = New-AzVmss `
    -ResourceGroupName $ResourceGroupName `
    -Name $ScaleSetName `
    -VirtualMachineScaleSet $VmssConfig

Write-Host "✅ VM Scale Set created successfully:"
Write-Host "  Name: $($Vmss.Name)"
Write-Host "  Location: $($Vmss.Location)"
Write-Host "  VM Size: $VmSize"
Write-Host "  Instance Count: $InstanceCount"
