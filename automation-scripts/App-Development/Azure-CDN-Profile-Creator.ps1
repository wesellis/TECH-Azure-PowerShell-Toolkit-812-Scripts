<#
.SYNOPSIS
    Manage CDN

.DESCRIPTION
    Manage CDN
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ProfileName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter(Mandatory)]
    [string]$EndpointName,
    [Parameter(Mandatory)]
    [string]$OriginHostName,
    [Parameter()]
    [string]$Sku = "Standard_Microsoft"
)
Write-Host "Creating CDN Profile: $ProfileName"
# Create CDN Profile
$params = @{
    Sku = $Sku
    ErrorAction = "Stop"
    ProfileName = $ProfileName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$CdnProfile @params
Write-Host "CDN Profile created: $($CdnProfile.Name)"
# Create CDN Endpoint
Write-Host "Creating CDN Endpoint: $EndpointName"
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
Write-Host "CDN Profile and Endpoint created successfully:"
Write-Host "Profile Name: $($CdnProfile.Name)"
Write-Host "SKU: $($CdnProfile.Sku.Name)"
Write-Host "Endpoint Name: $($CdnEndpoint.Name)"
Write-Host "Endpoint URL: https://$($CdnEndpoint.HostName)"
Write-Host "Origin: $OriginHostName"
Write-Host "`nCDN Benefits:"
Write-Host "Global content delivery"
Write-Host "Reduced latency"
Write-Host "Improved performance"
Write-Host "Bandwidth cost optimization"
Write-Host "Origin server protection"
Write-Host "`nNext Steps:"
Write-Host "1. Configure caching rules"
Write-Host "2. Set up custom domains"
Write-Host "3. Enable HTTPS"
Write-Host "4. Configure compression"
Write-Host "5. Test global distribution"

