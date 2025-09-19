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
    [string]$PublicIpName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$AllocationMethod = "Static",
    
    [Parameter(Mandatory=$false)]
    [string]$Sku = "Standard"
)

#region Functions

Write-Information "Creating Public IP: $PublicIpName"

$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Location = $Location
    AllocationMethod = $AllocationMethod
    ErrorAction = "Stop"
    Name = $PublicIpName
}
$PublicIp @params

Write-Information "Public IP created successfully:"
Write-Information "  Name: $($PublicIp.Name)"
Write-Information "  IP Address: $($PublicIp.IpAddress)"
Write-Information "  Allocation: $($PublicIp.PublicIpAllocationMethod)"
Write-Information "  SKU: $($PublicIp.Sku.Name)"


#endregion
