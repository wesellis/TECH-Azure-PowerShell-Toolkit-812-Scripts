#Requires -Version 7.4

<#`n.SYNOPSIS
    Manage CDN

.DESCRIPTION
    Manage CDN
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
Write-Output "Creating CDN Profile: $ProfileName"
$params = @{
    Sku = $Sku
    ErrorAction = "Stop"
    ProfileName = $ProfileName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$CdnProfile @params
Write-Output "CDN Profile created: $($CdnProfile.Name)"
Write-Output "Creating CDN Endpoint: $EndpointName"
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
Write-Output "CDN Profile and Endpoint created successfully:"
Write-Output "Profile Name: $($CdnProfile.Name)"
Write-Output "SKU: $($CdnProfile.Sku.Name)"
Write-Output "Endpoint Name: $($CdnEndpoint.Name)"
Write-Output "Endpoint URL: https://$($CdnEndpoint.HostName)"
Write-Output "Origin: $OriginHostName"
Write-Output "`nCDN Benefits:"
Write-Output "Global content delivery"
Write-Output "Reduced latency"
Write-Output "Improved performance"
Write-Output "Bandwidth cost optimization"
Write-Output "Origin server protection"
Write-Output "`nNext Steps:"
Write-Output "1. Configure caching rules"
Write-Output "2. Set up custom domains"
Write-Output "3. Enable HTTPS"
Write-Output "4. Configure compression"
Write-Output "5. Test global distribution"



