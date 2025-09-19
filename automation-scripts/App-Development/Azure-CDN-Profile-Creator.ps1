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
    [string]$ProfileName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$EndpointName,
    
    [Parameter(Mandatory=$true)]
    [string]$OriginHostName,
    
    [Parameter(Mandatory=$false)]
    [string]$Sku = "Standard_Microsoft"
)

#region Functions

Write-Information "Creating CDN Profile: $ProfileName"

# Create CDN Profile
$params = @{
    Sku = $Sku
    ErrorAction = "Stop"
    ProfileName = $ProfileName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$CdnProfile @params

Write-Information "CDN Profile created: $($CdnProfile.Name)"

# Create CDN Endpoint
Write-Information "Creating CDN Endpoint: $EndpointName"

$params = @{
    ResourceGroupName = $ResourceGroupName
    ProfileName = $ProfileName
    Location = $Location
    EndpointName = $EndpointName
    OriginHostName = $OriginHostName
    ErrorAction = "Stop"
    OriginName = "origin1"
}
$CdnEndpoint @params

Write-Information " CDN Profile and Endpoint created successfully:"
Write-Information "  Profile Name: $($CdnProfile.Name)"
Write-Information "  SKU: $($CdnProfile.Sku.Name)"
Write-Information "  Endpoint Name: $($CdnEndpoint.Name)"
Write-Information "  Endpoint URL: https://$($CdnEndpoint.HostName)"
Write-Information "  Origin: $OriginHostName"

Write-Information "`nCDN Benefits:"
Write-Information "• Global content delivery"
Write-Information "• Reduced latency"
Write-Information "• Improved performance"
Write-Information "• Bandwidth cost optimization"
Write-Information "• Origin server protection"

Write-Information "`nNext Steps:"
Write-Information "1. Configure caching rules"
Write-Information "2. Set up custom domains"
Write-Information "3. Enable HTTPS"
Write-Information "4. Configure compression"
Write-Information "5. Test global distribution"


#endregion
