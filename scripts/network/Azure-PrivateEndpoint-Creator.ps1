#Requires -Version 7.4
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Manage Private Endpoints

.DESCRIPTION
    Manage Private Endpoints
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$EndpointName,
    [Parameter(Mandatory)]
    [string]$SubnetId,
    [Parameter(Mandatory)]
    [string]$TargetResourceId,
    [Parameter(Mandatory)]
    [string]$GroupId,
    [Parameter(Mandatory)]
    [string]$Location
)
Write-Output "Creating Private Endpoint: $EndpointName"
$params = @{
    GroupId = $GroupId
    ErrorAction = "Stop"
    PrivateLinkServiceId = $TargetResourceId
    Name = $EndpointName-connection
}
$PrivateLinkServiceConnection @params
$params = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    PrivateLinkServiceConnection = $PrivateLinkServiceConnection
    Subnet = "@{Id=$SubnetId}"
    ErrorAction = "Stop"
    Name = $EndpointName
}
$PrivateEndpoint @params
Write-Output "Private Endpoint created successfully:"
Write-Output "Name: $($PrivateEndpoint.Name)"
Write-Output "Location: $($PrivateEndpoint.Location)"
Write-Output "Target Resource: $($TargetResourceId.Split('/')[-1])"
Write-Output "Group ID: $GroupId"
Write-Output "Private IP: $($PrivateEndpoint.NetworkInterfaces[0].IpConfigurations[0].PrivateIpAddress)"
Write-Output "`nNext Steps:"
Write-Output "1. Configure DNS records for the private endpoint"
Write-Output "2. Update network security groups if needed"
Write-Output "3. Test connectivity from the virtual network"



