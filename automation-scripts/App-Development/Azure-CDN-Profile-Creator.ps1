# ============================================================================
# Script Name: Azure CDN Profile Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure CDN Profile for global content delivery
# ============================================================================

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

Write-Host "Creating CDN Profile: $ProfileName"

# Create CDN Profile
$CdnProfile = New-AzCdnProfile `
    -ResourceGroupName $ResourceGroupName `
    -ProfileName $ProfileName `
    -Location $Location `
    -Sku $Sku

Write-Host "CDN Profile created: $($CdnProfile.Name)"

# Create CDN Endpoint
Write-Host "Creating CDN Endpoint: $EndpointName"

$CdnEndpoint = New-AzCdnEndpoint `
    -ResourceGroupName $ResourceGroupName `
    -ProfileName $ProfileName `
    -EndpointName $EndpointName `
    -Location $Location `
    -OriginHostName $OriginHostName `
    -OriginName "origin1"

Write-Host "✅ CDN Profile and Endpoint created successfully:"
Write-Host "  Profile Name: $($CdnProfile.Name)"
Write-Host "  SKU: $($CdnProfile.Sku.Name)"
Write-Host "  Endpoint Name: $($CdnEndpoint.Name)"
Write-Host "  Endpoint URL: https://$($CdnEndpoint.HostName)"
Write-Host "  Origin: $OriginHostName"

Write-Host "`nCDN Benefits:"
Write-Host "• Global content delivery"
Write-Host "• Reduced latency"
Write-Host "• Improved performance"
Write-Host "• Bandwidth cost optimization"
Write-Host "• Origin server protection"

Write-Host "`nNext Steps:"
Write-Host "1. Configure caching rules"
Write-Host "2. Set up custom domains"
Write-Host "3. Enable HTTPS"
Write-Host "4. Configure compression"
Write-Host "5. Test global distribution"
