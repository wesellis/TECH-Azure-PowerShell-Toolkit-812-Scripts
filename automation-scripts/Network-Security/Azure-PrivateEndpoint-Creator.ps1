<#
.SYNOPSIS
    Manage Private Endpoints

.DESCRIPTION
    Manage Private Endpoints
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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
Write-Host "Creating Private Endpoint: $EndpointName"
# Create private endpoint
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
Write-Host "Private Endpoint created successfully:"
Write-Host "Name: $($PrivateEndpoint.Name)"
Write-Host "Location: $($PrivateEndpoint.Location)"
Write-Host "Target Resource: $($TargetResourceId.Split('/')[-1])"
Write-Host "Group ID: $GroupId"
Write-Host "Private IP: $($PrivateEndpoint.NetworkInterfaces[0].IpConfigurations[0].PrivateIpAddress)"
Write-Host "`nNext Steps:"
Write-Host "1. Configure DNS records for the private endpoint"
Write-Host "2. Update network security groups if needed"
Write-Host "3. Test connectivity from the virtual network"

