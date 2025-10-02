#Requires -Version 7.4

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
    [string]$NicName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter(Mandatory)]
    [string]$SubnetId,
    [Parameter()]
    [string]$PublicIpId
)
Write-Output "Creating Network Interface: $NicName"
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
Write-Output "Network Interface created successfully:"
Write-Output "Name: $($Nic.Name)"
Write-Output "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
Write-Output "Location: $($Nic.Location)"



