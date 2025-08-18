# ============================================================================
# Script Name: Azure DNS Zone Health Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure DNS Zone health, record sets, and resolution performance
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ZoneName
)

Write-Information "Monitoring DNS Zone: $ZoneName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get DNS Zone details
$DnsZone = Get-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName

Write-Information "DNS Zone Information:"
Write-Information "  Zone Name: $($DnsZone.Name)"
Write-Information "  Resource Group: $($DnsZone.ResourceGroupName)"
Write-Information "  Number of Record Sets: $($DnsZone.NumberOfRecordSets)"
Write-Information "  Max Number of Record Sets: $($DnsZone.MaxNumberOfRecordSets)"

# Display name servers
Write-Information "`nName Servers:"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Information "  $NameServer"
}

# Get all record sets
Write-Information "`nDNS Record Sets:"
$RecordSets = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName

# Group by record type for summary
$RecordSummary = $RecordSets | Group-Object RecordType
Write-Information "`nRecord Type Summary:"
foreach ($Group in $RecordSummary) {
    Write-Information "  $($Group.Name): $($Group.Count) records"
}

# Display detailed record information
Write-Information "`nDetailed Record Sets:"
foreach ($RecordSet in $RecordSets | Sort-Object RecordType, Name) {
    Write-Information "  - Name: $($RecordSet.Name)"
    Write-Information "    Type: $($RecordSet.RecordType)"
    Write-Information "    TTL: $($RecordSet.Ttl) seconds"
    
    # Display records based on type
    switch ($RecordSet.RecordType) {
        "A" {
            foreach ($Record in $RecordSet.Records) {
                Write-Information "    Value: $($Record.Ipv4Address)"
            }
        }
        "AAAA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Information "    Value: $($Record.Ipv6Address)"
            }
        }
        "CNAME" {
            foreach ($Record in $RecordSet.Records) {
                Write-Information "    Value: $($Record.Cname)"
            }
        }
        "MX" {
            foreach ($Record in $RecordSet.Records) {
                Write-Information "    Value: $($Record.Preference) $($Record.Exchange)"
            }
        }
        "NS" {
            foreach ($Record in $RecordSet.Records) {
                Write-Information "    Value: $($Record.Nsdname)"
            }
        }
        "TXT" {
            foreach ($Record in $RecordSet.Records) {
                $TxtValue = ($Record.Value -join ' ').Substring(0, [Math]::Min(50, ($Record.Value -join ' ').Length))
                Write-Information "    Value: $TxtValue..."
            }
        }
        "SOA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Information "    Host: $($Record.Host)"
                Write-Information "    Email: $($Record.Email)"
                Write-Information "    Serial: $($Record.SerialNumber)"
                Write-Information "    Refresh: $($Record.RefreshTime)"
                Write-Information "    Retry: $($Record.RetryTime)"
                Write-Information "    Expire: $($Record.ExpireTime)"
                Write-Information "    Minimum TTL: $($Record.MinimumTtl)"
            }
        }
    }
    Write-Information "    ---"
}

# Check for common DNS configuration issues
Write-Information "`nDNS Health Checks:"

# Check for missing essential records
$HasSOA = $RecordSets | Where-Object { $_.RecordType -eq "SOA" -and $_.Name -eq "@" }
$HasNS = $RecordSets | Where-Object { $_.RecordType -eq "NS" -and $_.Name -eq "@" }
$HasA = $RecordSets | Where-Object { $_.RecordType -eq "A" -and $_.Name -eq "@" }
$HasWWW = $RecordSets | Where-Object { $_.Name -eq "www" }

Write-Information "  ✓ SOA Record: $(if ($HasSOA) { 'Present' } else { 'Missing' })"
Write-Information "  ✓ NS Records: $(if ($HasNS) { 'Present' } else { 'Missing' })"
Write-Information "  ✓ Root A Record: $(if ($HasA) { 'Present' } else { 'Missing (Optional)' })"
Write-Information "  ✓ WWW Record: $(if ($HasWWW) { 'Present' } else { 'Missing (Recommended)' })"

# Check TTL values
$LowTTLRecords = $RecordSets | Where-Object { $_.Ttl -lt 300 -and $_.RecordType -ne "SOA" }
if ($LowTTLRecords.Count -gt 0) {
    Write-Information "  ⚠ Low TTL Warning: $($LowTTLRecords.Count) records have TTL < 5 minutes"
    foreach ($Record in $LowTTLRecords) {
        Write-Information "    - $($Record.Name) ($($Record.RecordType)): $($Record.Ttl)s"
    }
}

$HighTTLRecords = $RecordSets | Where-Object { $_.Ttl -gt 86400 -and $_.RecordType -ne "SOA" -and $_.RecordType -ne "NS" }
if ($HighTTLRecords.Count -gt 0) {
    Write-Information "  ⚠ High TTL Warning: $($HighTTLRecords.Count) records have TTL > 24 hours"
}

# DNS resolution test
Write-Information "`nDNS Resolution Test:"
try {
    # Test resolution of the zone itself
    $ResolutionTest = Resolve-DnsName -Name $ZoneName -Type NS -ErrorAction SilentlyContinue
    if ($ResolutionTest) {
        Write-Information "  ✓ Zone resolution: Successful"
        Write-Information "    Responding name servers:"
        foreach ($NS in $ResolutionTest | Where-Object { $_.Type -eq "NS" }) {
            Write-Information "      $($NS.NameHost)"
        }
    } else {
        Write-Information "  ✗ Zone resolution: Failed"
    }
    
    # Test A record resolution if exists
    if ($HasA) {
        $ARecordTest = Resolve-DnsName -Name $ZoneName -Type A -ErrorAction SilentlyContinue
        if ($ARecordTest) {
            Write-Information "  ✓ A record resolution: Successful"
            foreach ($A in $ARecordTest | Where-Object { $_.Type -eq "A" }) {
                Write-Information "    $($ZoneName) -> $($A.IPAddress)"
            }
        }
    }
    
} catch {
    Write-Information "  ⚠ DNS resolution test failed: $($_.Exception.Message)"
}

Write-Information "`nRecommendations:"
Write-Information "1. Ensure proper TTL values for your use case"
Write-Information "2. Verify name server configuration at your registrar"
Write-Information "3. Monitor DNS query patterns and performance"
Write-Information "4. Consider adding health checks for critical records"
Write-Information "5. Implement DNS monitoring and alerting"

Write-Information "`nDNS Zone monitoring completed at $(Get-Date)"
