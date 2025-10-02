#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage DNS

.DESCRIPTION
    Manage DNS
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$ZoneName,
    [array]$Tags = @()
)
Write-Output "Provisioning DNS Zone: $ZoneName"
Write-Output "Resource Group: $ResourceGroupName"
if ($ZoneName -notmatch "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$") {
    throw "Invalid DNS zone name format. Please provide a valid domain name."
}
if ($Tags.Count -gt 0) {
    $DnsZone = New-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName -Tag $Tags
} else {
    $DnsZone = New-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName
}
Write-Output "`nDNS Zone $ZoneName provisioned successfully"
Write-Output "Zone ID: $($DnsZone.Id)"
Write-Output "Number of Record Sets: $($DnsZone.NumberOfRecordSets)"
Write-Output "`nName Servers (configure these at your domain registrar):"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Output "  $NameServer"
}
Write-Output "`nDefault Record Sets Created:"
Write-Output "NS (Name Server) records"
Write-Output "SOA (Start of Authority) record"
Write-Output "`nNext Steps:"
Write-Output "1. Update your domain registrar with the above name servers"
Write-Output "2. Add A, CNAME, MX, or other DNS records as needed"
Write-Output "3. Verify DNS propagation using nslookup or dig"
Write-Output "`nDNS Zone provisioning completed at $(Get-Date)"



