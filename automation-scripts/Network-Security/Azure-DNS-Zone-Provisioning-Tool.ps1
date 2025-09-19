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
    [string]$ResourceGroupName,
    [string]$ZoneName,
    [array]$Tags = @()
)

#region Functions

Write-Information "Provisioning DNS Zone: $ZoneName"
Write-Information "Resource Group: $ResourceGroupName"

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

Write-Information "`nDNS Zone $ZoneName provisioned successfully"
Write-Information "Zone ID: $($DnsZone.Id)"
Write-Information "Number of Record Sets: $($DnsZone.NumberOfRecordSets)"

# Display name servers
Write-Information "`nName Servers (configure these at your domain registrar):"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Information "  $NameServer"
}

Write-Information "`nDefault Record Sets Created:"
Write-Information "  NS (Name Server) records"
Write-Information "  SOA (Start of Authority) record"

Write-Information "`nNext Steps:"
Write-Information "1. Update your domain registrar with the above name servers"
Write-Information "2. Add A, CNAME, MX, or other DNS records as needed"
Write-Information "3. Verify DNS propagation using nslookup or dig"

Write-Information "`nDNS Zone provisioning completed at $(Get-Date)"


#endregion
