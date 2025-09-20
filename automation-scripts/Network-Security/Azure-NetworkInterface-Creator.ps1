<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
param (
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
Write-Host "Creating Network Interface: $NicName"
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
Write-Host "Network Interface created successfully:"
Write-Host "Name: $($Nic.Name)"
Write-Host "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
Write-Host "Location: $($Nic.Location)"

