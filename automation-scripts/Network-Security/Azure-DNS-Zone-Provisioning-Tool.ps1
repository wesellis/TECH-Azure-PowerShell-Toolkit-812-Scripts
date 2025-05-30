# ============================================================================
# Script Name: Azure DNS Zone Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure DNS zones for domain name management and resolution
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ZoneName,
    [array]$Tags = @()
)

Write-Host "Provisioning DNS Zone: $ZoneName"
Write-Host "Resource Group: $ResourceGroupName"

# Validate zone name format
if ($ZoneName -notmatch "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$") {
    throw "Invalid DNS zone name format. Please provide a valid domain name."
}

# Create the DNS Zone
if ($Tags.Count -gt 0) {
    $DnsZone = New-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName -Tag $Tags
} else {
    $DnsZone = New-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName
}

Write-Host "`nDNS Zone $ZoneName provisioned successfully"
Write-Host "Zone ID: $($DnsZone.Id)"
Write-Host "Number of Record Sets: $($DnsZone.NumberOfRecordSets)"

# Display name servers
Write-Host "`nName Servers (configure these at your domain registrar):"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Host "  $NameServer"
}

Write-Host "`nDefault Record Sets Created:"
Write-Host "  NS (Name Server) records"
Write-Host "  SOA (Start of Authority) record"

Write-Host "`nNext Steps:"
Write-Host "1. Update your domain registrar with the above name servers"
Write-Host "2. Add A, CNAME, MX, or other DNS records as needed"
Write-Host "3. Verify DNS propagation using nslookup or dig"

Write-Host "`nDNS Zone provisioning completed at $(Get-Date)"
