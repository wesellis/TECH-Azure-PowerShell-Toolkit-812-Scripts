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

Write-Information "Creating CDN Profile: $ProfileName"

# Create CDN Profile
$CdnProfile = New-AzCdnProfile -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -ProfileName $ProfileName `
    -Location $Location `
    -Sku $Sku

Write-Information "CDN Profile created: $($CdnProfile.Name)"

# Create CDN Endpoint
Write-Information "Creating CDN Endpoint: $EndpointName"

$CdnEndpoint = New-AzCdnEndpoint -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -ProfileName $ProfileName `
    -EndpointName $EndpointName `
    -Location $Location `
    -OriginHostName $OriginHostName `
    -OriginName "origin1"

Write-Information "✅ CDN Profile and Endpoint created successfully:"
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
