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

Write-Host "Monitoring DNS Zone: $ZoneName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get DNS Zone details
$DnsZone = Get-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName

Write-Host "DNS Zone Information:"
Write-Host "  Zone Name: $($DnsZone.Name)"
Write-Host "  Resource Group: $($DnsZone.ResourceGroupName)"
Write-Host "  Number of Record Sets: $($DnsZone.NumberOfRecordSets)"
Write-Host "  Max Number of Record Sets: $($DnsZone.MaxNumberOfRecordSets)"

# Display name servers
Write-Host "`nName Servers:"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Host "  $NameServer"
}

# Get all record sets
Write-Host "`nDNS Record Sets:"
$RecordSets = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName

# Group by record type for summary
$RecordSummary = $RecordSets | Group-Object RecordType
Write-Host "`nRecord Type Summary:"
foreach ($Group in $RecordSummary) {
    Write-Host "  $($Group.Name): $($Group.Count) records"
}

# Display detailed record information
Write-Host "`nDetailed Record Sets:"
foreach ($RecordSet in $RecordSets | Sort-Object RecordType, Name) {
    Write-Host "  - Name: $($RecordSet.Name)"
    Write-Host "    Type: $($RecordSet.RecordType)"
    Write-Host "    TTL: $($RecordSet.Ttl) seconds"
    
    # Display records based on type
    switch ($RecordSet.RecordType) {
        "A" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Ipv4Address)"
            }
        }
        "AAAA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Ipv6Address)"
            }
        }
        "CNAME" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Cname)"
            }
        }
        "MX" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Preference) $($Record.Exchange)"
            }
        }
        "NS" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Nsdname)"
            }
        }
        "TXT" {
            foreach ($Record in $RecordSet.Records) {
                $TxtValue = ($Record.Value -join ' ').Substring(0, [Math]::Min(50, ($Record.Value -join ' ').Length))
                Write-Host "    Value: $TxtValue..."
            }
        }
        "SOA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Host: $($Record.Host)"
                Write-Host "    Email: $($Record.Email)"
                Write-Host "    Serial: $($Record.SerialNumber)"
                Write-Host "    Refresh: $($Record.RefreshTime)"
                Write-Host "    Retry: $($Record.RetryTime)"
                Write-Host "    Expire: $($Record.ExpireTime)"
                Write-Host "    Minimum TTL: $($Record.MinimumTtl)"
            }
        }
    }
    Write-Host "    ---"
}

# Check for common DNS configuration issues
Write-Host "`nDNS Health Checks:"

# Check for missing essential records
$HasSOA = $RecordSets | Where-Object { $_.RecordType -eq "SOA" -and $_.Name -eq "@" }
$HasNS = $RecordSets | Where-Object { $_.RecordType -eq "NS" -and $_.Name -eq "@" }
$HasA = $RecordSets | Where-Object { $_.RecordType -eq "A" -and $_.Name -eq "@" }
$HasWWW = $RecordSets | Where-Object { $_.Name -eq "www" }

Write-Host "  ✓ SOA Record: $(if ($HasSOA) { 'Present' } else { 'Missing' })"
Write-Host "  ✓ NS Records: $(if ($HasNS) { 'Present' } else { 'Missing' })"
Write-Host "  ✓ Root A Record: $(if ($HasA) { 'Present' } else { 'Missing (Optional)' })"
Write-Host "  ✓ WWW Record: $(if ($HasWWW) { 'Present' } else { 'Missing (Recommended)' })"

# Check TTL values
$LowTTLRecords = $RecordSets | Where-Object { $_.Ttl -lt 300 -and $_.RecordType -ne "SOA" }
if ($LowTTLRecords.Count -gt 0) {
    Write-Host "  ⚠ Low TTL Warning: $($LowTTLRecords.Count) records have TTL < 5 minutes"
    foreach ($Record in $LowTTLRecords) {
        Write-Host "    - $($Record.Name) ($($Record.RecordType)): $($Record.Ttl)s"
    }
}

$HighTTLRecords = $RecordSets | Where-Object { $_.Ttl -gt 86400 -and $_.RecordType -ne "SOA" -and $_.RecordType -ne "NS" }
if ($HighTTLRecords.Count -gt 0) {
    Write-Host "  ⚠ High TTL Warning: $($HighTTLRecords.Count) records have TTL > 24 hours"
}

# DNS resolution test
Write-Host "`nDNS Resolution Test:"
try {
    # Test resolution of the zone itself
    $ResolutionTest = Resolve-DnsName -Name $ZoneName -Type NS -ErrorAction SilentlyContinue
    if ($ResolutionTest) {
        Write-Host "  ✓ Zone resolution: Successful"
        Write-Host "    Responding name servers:"
        foreach ($NS in $ResolutionTest | Where-Object { $_.Type -eq "NS" }) {
            Write-Host "      $($NS.NameHost)"
        }
    } else {
        Write-Host "  ✗ Zone resolution: Failed"
    }
    
    # Test A record resolution if exists
    if ($HasA) {
        $ARecordTest = Resolve-DnsName -Name $ZoneName -Type A -ErrorAction SilentlyContinue
        if ($ARecordTest) {
            Write-Host "  ✓ A record resolution: Successful"
            foreach ($A in $ARecordTest | Where-Object { $_.Type -eq "A" }) {
                Write-Host "    $($ZoneName) -> $($A.IPAddress)"
            }
        }
    }
    
} catch {
    Write-Host "  ⚠ DNS resolution test failed: $($_.Exception.Message)"
}

Write-Host "`nRecommendations:"
Write-Host "1. Ensure proper TTL values for your use case"
Write-Host "2. Verify name server configuration at your registrar"
Write-Host "3. Monitor DNS query patterns and performance"
Write-Host "4. Consider adding health checks for critical records"
Write-Host "5. Implement DNS monitoring and alerting"

Write-Host "`nDNS Zone monitoring completed at $(Get-Date)"
