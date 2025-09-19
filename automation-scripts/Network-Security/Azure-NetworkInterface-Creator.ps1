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
    [string]$NicName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$SubnetId,
    
    [Parameter(Mandatory=$false)]
    [string]$PublicIpId
)

#region Functions

Write-Information "Creating Network Interface: $NicName"

if ($PublicIpId) {
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        PublicIpAddressId = $PublicIpId
        SubnetId = $SubnetId
        ErrorAction = "Stop"
        Name = $NicName
    }
    $Nic @params
} else {
    $params = @{
        ErrorAction = "Stop"
        SubnetId = $SubnetId
        ResourceGroupName = $ResourceGroupName
        Name = $NicName
        Location = $Location
    }
    $Nic @params
}

Write-Information "Network Interface created successfully:"
Write-Information "  Name: $($Nic.Name)"
Write-Information "  Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
Write-Information "  Location: $($Nic.Location)"


#endregion
