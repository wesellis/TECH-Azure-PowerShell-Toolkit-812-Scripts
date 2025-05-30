# ============================================================================
# Script Name: Azure Private Endpoint Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Private Endpoints for secure service connectivity
# ============================================================================

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

Write-Host "Creating Private Endpoint: $EndpointName"

# Create private endpoint
$PrivateLinkServiceConnection = New-AzPrivateLinkServiceConnection `
    -Name "$EndpointName-connection" `
    -PrivateLinkServiceId $TargetResourceId `
    -GroupId $GroupId

$PrivateEndpoint = New-AzPrivateEndpoint `
    -ResourceGroupName $ResourceGroupName `
    -Name $EndpointName `
    -Location $Location `
    -Subnet @{Id=$SubnetId} `
    -PrivateLinkServiceConnection $PrivateLinkServiceConnection

Write-Host "✅ Private Endpoint created successfully:"
Write-Host "  Name: $($PrivateEndpoint.Name)"
Write-Host "  Location: $($PrivateEndpoint.Location)"
Write-Host "  Target Resource: $($TargetResourceId.Split('/')[-1])"
Write-Host "  Group ID: $GroupId"
Write-Host "  Private IP: $($PrivateEndpoint.NetworkInterfaces[0].IpConfigurations[0].PrivateIpAddress)"

Write-Host "`nNext Steps:"
Write-Host "1. Configure DNS records for the private endpoint"
Write-Host "2. Update network security groups if needed"
Write-Host "3. Test connectivity from the virtual network"
