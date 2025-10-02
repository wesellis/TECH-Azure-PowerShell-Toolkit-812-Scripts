#Requires -Version 7.4

<#`n.SYNOPSIS
    Manage Public IPs

.DESCRIPTION
    Manage Public IPs
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$PublicIpName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$AllocationMethod = "Static",
    [Parameter()]
    [string]$Sku = "Standard"
)
Write-Output "Creating Public IP: $PublicIpName"
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Location = $Location
    AllocationMethod = $AllocationMethod
    ErrorAction = "Stop"
    Name = $PublicIpName
}
$PublicIp @params
Write-Output "Public IP created successfully:"
Write-Output "Name: $($PublicIp.Name)"
Write-Output "IP Address: $($PublicIp.IpAddress)"
Write-Output "Allocation: $($PublicIp.PublicIpAllocationMethod)"
Write-Output "SKU: $($PublicIp.Sku.Name)"



