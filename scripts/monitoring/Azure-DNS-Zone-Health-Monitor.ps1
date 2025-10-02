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
    [string]$ZoneName
)
Write-Output "Monitoring DNS Zone: $ZoneName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$DnsZone = Get-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName
Write-Output "DNS Zone Information:"
Write-Output "Zone Name: $($DnsZone.Name)"
Write-Output "Resource Group: $($DnsZone.ResourceGroupName)"
Write-Output "Number of Record Sets: $($DnsZone.NumberOfRecordSets)"
Write-Output "Max Number of Record Sets: $($DnsZone.MaxNumberOfRecordSets)"
Write-Output "`nName Servers:"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Output "  $NameServer"
}
Write-Output "`nDNS Record Sets:"
$RecordSets = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName
$RecordSummary = $RecordSets | Group-Object RecordType
Write-Output "`nRecord Type Summary:"
foreach ($Group in $RecordSummary) {
    Write-Output "  $($Group.Name): $($Group.Count) records"
}
Write-Output "`n Record Sets:"
foreach ($RecordSet in $RecordSets | Sort-Object RecordType, Name) {
    Write-Output "  - Name: $($RecordSet.Name)"
    Write-Output "    Type: $($RecordSet.RecordType)"
    Write-Output "    TTL: $($RecordSet.Ttl) seconds"
    switch ($RecordSet.RecordType) {
        "A" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Ipv4Address)"
            }
        }
        "AAAA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Ipv6Address)"
            }
        }
        "CNAME" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Cname)"
            }
        }
        "MX" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Preference) $($Record.Exchange)"
            }
        }
        "NS" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Nsdname)"
            }
        }
        "TXT" {
            foreach ($Record in $RecordSet.Records) {
                $TxtValue = ($Record.Value -join ' ').Substring(0, [Math]::Min(50, ($Record.Value -join ' ').Length))
                Write-Output "    Value: $TxtValue..."
            }
        }
        "SOA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Host: $($Record.Host)"
                Write-Output "    Email: $($Record.Email)"
                Write-Output "    Serial: $($Record.SerialNumber)"
                Write-Output "    Refresh: $($Record.RefreshTime)"
                Write-Output "    Retry: $($Record.RetryTime)"
                Write-Output "    Expire: $($Record.ExpireTime)"
                Write-Output "    Minimum TTL: $($Record.MinimumTtl)"
            }
        }
    }
    Write-Output "    ---"
}
Write-Output "`nDNS Health Checks:"
$HasSOA = $RecordSets | Where-Object { $_.RecordType -eq "SOA" -and $_.Name -eq "@" }
$HasNS = $RecordSets | Where-Object { $_.RecordType -eq "NS" -and $_.Name -eq "@" }
$HasA = $RecordSets | Where-Object { $_.RecordType -eq "A" -and $_.Name -eq "@" }
$HasWWW = $RecordSets | Where-Object { $_.Name -eq "www" }
Write-Output "  [OK] SOA Record: $(if ($HasSOA) { 'Present' } else { 'Missing' })"
Write-Output "  [OK] NS Records: $(if ($HasNS) { 'Present' } else { 'Missing' })"
Write-Output "  [OK] Root A Record: $(if ($HasA) { 'Present' } else { 'Missing (Optional)' })"
Write-Output "  [OK] WWW Record: $(if ($HasWWW) { 'Present' } else { 'Missing (Recommended)' })"
$LowTTLRecords = $RecordSets | Where-Object { $_.Ttl -lt 300 -and $_.RecordType -ne "SOA" }
if ($LowTTLRecords.Count -gt 0) {
    Write-Output "  [WARN] Low TTL Warning: $($LowTTLRecords.Count) records have TTL < 5 minutes"
    foreach ($Record in $LowTTLRecords) {
        Write-Output "    - $($Record.Name) ($($Record.RecordType)): $($Record.Ttl)s"
    }
}
$HighTTLRecords = $RecordSets | Where-Object { $_.Ttl -gt 86400 -and $_.RecordType -ne "SOA" -and $_.RecordType -ne "NS" }
if ($HighTTLRecords.Count -gt 0) {
    Write-Output "  [WARN] High TTL Warning: $($HighTTLRecords.Count) records have TTL > 24 hours"
}
Write-Output "`nDNS Resolution Test:"
try {
    $ResolutionTest = Resolve-DnsName -Name $ZoneName -Type NS -ErrorAction SilentlyContinue
    if ($ResolutionTest) {
        Write-Output "  [OK] Zone resolution: Successful"
        Write-Output "    Responding name servers:"
        foreach ($NS in $ResolutionTest | Where-Object { $_.Type -eq "NS" }) {
            Write-Output "      $($NS.NameHost)"
        }
    } else {
        Write-Output "  [FAIL] Zone resolution: Failed"
    }
    if ($HasA) {
        $ARecordTest = Resolve-DnsName -Name $ZoneName -Type A -ErrorAction SilentlyContinue
        if ($ARecordTest) {
            Write-Output "  [OK] A record resolution: Successful"
            foreach ($A in $ARecordTest | Where-Object { $_.Type -eq "A" }) {
                Write-Output "    $($ZoneName) -> $($A.IPAddress)"
            }
        }
    }
} catch {
    Write-Output "  [WARN] DNS resolution test failed: $($_.Exception.Message)"
}
Write-Output "`nRecommendations:"
Write-Output "1. Ensure proper TTL values for your use case"
Write-Output "2. Verify name server configuration at your registrar"
Write-Output "3. Monitor DNS query patterns and performance"
Write-Output "4. Consider adding health checks for critical records"
Write-Output "5. Implement DNS monitoring and alerting"
Write-Output "`nDNS Zone monitoring completed at $(Get-Date)"



