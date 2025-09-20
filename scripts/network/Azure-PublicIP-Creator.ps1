#Requires -Version 7.0

<#`n.SYNOPSIS
    Manage Public IPs

.DESCRIPTION
    Manage Public IPs
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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
Write-Host "Creating Public IP: $PublicIpName"
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Location = $Location
    AllocationMethod = $AllocationMethod
    ErrorAction = "Stop"
    Name = $PublicIpName
}
$PublicIp @params
Write-Host "Public IP created successfully:"
Write-Host "Name: $($PublicIp.Name)"
Write-Host "IP Address: $($PublicIp.IpAddress)"
Write-Host "Allocation: $($PublicIp.PublicIpAllocationMethod)"
Write-Host "SKU: $($PublicIp.Sku.Name)"

