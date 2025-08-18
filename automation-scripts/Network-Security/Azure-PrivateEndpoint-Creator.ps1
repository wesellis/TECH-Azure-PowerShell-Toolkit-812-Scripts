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

Write-Information "Creating Private Endpoint: $EndpointName"

# Create private endpoint
$PrivateLinkServiceConnection = New-AzPrivateLinkServiceConnection -ErrorAction Stop `
    -Name "$EndpointName-connection" `
    -PrivateLinkServiceId $TargetResourceId `
    -GroupId $GroupId

$PrivateEndpoint = New-AzPrivateEndpoint -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $EndpointName `
    -Location $Location `
    -Subnet @{Id=$SubnetId} `
    -PrivateLinkServiceConnection $PrivateLinkServiceConnection

Write-Information "✅ Private Endpoint created successfully:"
Write-Information "  Name: $($PrivateEndpoint.Name)"
Write-Information "  Location: $($PrivateEndpoint.Location)"
Write-Information "  Target Resource: $($TargetResourceId.Split('/')[-1])"
Write-Information "  Group ID: $GroupId"
Write-Information "  Private IP: $($PrivateEndpoint.NetworkInterfaces[0].IpConfigurations[0].PrivateIpAddress)"

Write-Information "`nNext Steps:"
Write-Information "1. Configure DNS records for the private endpoint"
Write-Information "2. Update network security groups if needed"
Write-Information "3. Test connectivity from the virtual network"
