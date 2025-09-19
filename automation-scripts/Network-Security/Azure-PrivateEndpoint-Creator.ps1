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
    [string]$EndpointName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubnetId,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetResourceId,
    
    [Parameter(Mandatory=$true)]
    [string]$GroupId,
    
    [Parameter(Mandatory=$true)]
    [string]$Location
)

#region Functions

Write-Information "Creating Private Endpoint: $EndpointName"

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

Write-Information " Private Endpoint created successfully:"
Write-Information "  Name: $($PrivateEndpoint.Name)"
Write-Information "  Location: $($PrivateEndpoint.Location)"
Write-Information "  Target Resource: $($TargetResourceId.Split('/')[-1])"
Write-Information "  Group ID: $GroupId"
Write-Information "  Private IP: $($PrivateEndpoint.NetworkInterfaces[0].IpConfigurations[0].PrivateIpAddress)"

Write-Information "`nNext Steps:"
Write-Information "1. Configure DNS records for the private endpoint"
Write-Information "2. Update network security groups if needed"
Write-Information "3. Test connectivity from the virtual network"


#endregion
