#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Create Azure virtual machine

.DESCRIPTION
    Create Azure virtual machine operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$ImageName,

    [Parameter(Mandatory = $true)]
    [string]$ImageResourceGroupName,

    [Parameter()]
    [string]$VirtualNetworkName,

    [Parameter()]
    [string]$SubnetName,

    [Parameter()]
    [string]$SecurityGroupName,

    [Parameter()]
    [string]$PublicIpAddressName,

    [Parameter()]
    [int[]]$OpenPorts = @(3389),

    [Parameter()]
    [hashtable]$Tags
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$image = Get-AzImage -ResourceGroupName $ImageResourceGroupName -ImageName $ImageName -ErrorAction Stop

$newAzVmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $VMName
    Image = $image.Id
    Location = $Location
    OpenPorts = $OpenPorts
}

if ($VirtualNetworkName) {
    $newAzVmSplat.VirtualNetworkName = $VirtualNetworkName
}

if ($SubnetName) {
    $newAzVmSplat.SubnetName = $SubnetName
}

if ($SecurityGroupName) {
    $newAzVmSplat.SecurityGroupName = $SecurityGroupName
}

if ($PublicIpAddressName) {
    $newAzVmSplat.PublicIpAddressName = $PublicIpAddressName
}

$vm = New-AzVm @newAzVmSplat -ErrorAction Stop

if ($Tags) {
    Set-AzResource -ResourceId $vm.Id -Tag $Tags -Force -ErrorAction Stop
}

$vm


