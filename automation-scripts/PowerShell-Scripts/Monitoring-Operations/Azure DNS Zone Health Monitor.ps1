#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Dns Zone Health Monitor

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$ZoneName
)
Write-Host "Monitoring DNS Zone: $ZoneName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host " ============================================" "INFO"
$DnsZone = Get-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName
Write-Host "DNS Zone Information:" "INFO"
Write-Host "Zone Name: $($DnsZone.Name)" "INFO"
Write-Host "Resource Group: $($DnsZone.ResourceGroupName)" "INFO"
Write-Host "Number of Record Sets: $($DnsZone.NumberOfRecordSets)" "INFO"
Write-Host "Max Number of Record Sets: $($DnsZone.MaxNumberOfRecordSets)" "INFO"
Write-Host " `nName Servers:" "INFO"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Host "  $NameServer" "INFO"
}
Write-Host " `nDNS Record Sets:" "INFO"
$RecordSets = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName
$RecordSummary = $RecordSets | Group-Object RecordType
Write-Host " `nRecord Type Summary:" "INFO"
foreach ($Group in $RecordSummary) {
    Write-Host "  $($Group.Name): $($Group.Count) records" "INFO"
}
Write-Host " `n Record Sets:" "INFO"
foreach ($RecordSet in $RecordSets | Sort-Object RecordType, Name) {
    Write-Host "  - Name: $($RecordSet.Name)" "INFO"
    Write-Host "    Type: $($RecordSet.RecordType)" "INFO"
    Write-Host "    TTL: $($RecordSet.Ttl) seconds" "INFO"
    # Display records based on type
    switch ($RecordSet.RecordType) {
        "A" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Ipv4Address)" "INFO"
            }
        }
        "AAAA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Ipv6Address)" "INFO"
            }
        }
        "CNAME" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Cname)" "INFO"
            }
        }
        "MX" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Preference) $($Record.Exchange)" "INFO"
            }
        }
        "NS" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Value: $($Record.Nsdname)" "INFO"
            }
        }
        "TXT" {
            foreach ($Record in $RecordSet.Records) {
                $TxtValue = ($Record.Value -join ' ').Substring(0, [Math]::Min(50, ($Record.Value -join ' ').Length))
                Write-Host "    Value: $TxtValue..." "INFO"
            }
        }
        "SOA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Host "    Host: $($Record.Host)" "INFO"
                Write-Host "    Email: $($Record.Email)" "INFO"
                Write-Host "    Serial: $($Record.SerialNumber)" "INFO"
                Write-Host "    Refresh: $($Record.RefreshTime)" "INFO"
                Write-Host "    Retry: $($Record.RetryTime)" "INFO"
                Write-Host "    Expire: $($Record.ExpireTime)" "INFO"
                Write-Host "    Minimum TTL: $($Record.MinimumTtl)" "INFO"
            }
        }
    }
    Write-Host "    ---" "INFO"
}
Write-Host " `nDNS Health Checks:" "INFO"
$HasSOA = $RecordSets | Where-Object { $_.RecordType -eq "SOA" -and $_.Name -eq " @" }
$HasNS = $RecordSets | Where-Object { $_.RecordType -eq "NS" -and $_.Name -eq " @" }
$HasA = $RecordSets | Where-Object { $_.RecordType -eq "A" -and $_.Name -eq " @" }
$HasWWW = $RecordSets | Where-Object { $_.Name -eq " www" }
Write-Host "  [OK] SOA Record: $(if ($HasSOA) { 'Present' } else { 'Missing' })" "INFO"
Write-Host "  [OK] NS Records: $(if ($HasNS) { 'Present' } else { 'Missing' })" "INFO"
Write-Host "  [OK] Root A Record: $(if ($HasA) { 'Present' } else { 'Missing (Optional)' })" "INFO"
Write-Host "  [OK] WWW Record: $(if ($HasWWW) { 'Present' } else { 'Missing (Recommended)' })" "INFO"
$LowTTLRecords = $RecordSets | Where-Object { $_.Ttl -lt 300 -and $_.RecordType -ne "SOA" }
if ($LowTTLRecords.Count -gt 0) {
    Write-Host "  [WARN] Low TTL Warning: $($LowTTLRecords.Count) records have TTL < 5 minutes" "INFO"
    foreach ($Record in $LowTTLRecords) {
        Write-Host "    - $($Record.Name) ($($Record.RecordType)): $($Record.Ttl)s" "INFO"
    }
}
$HighTTLRecords = $RecordSets | Where-Object { $_.Ttl -gt 86400 -and $_.RecordType -ne "SOA" -and $_.RecordType -ne "NS" }
if ($HighTTLRecords.Count -gt 0) {
    Write-Host "  [WARN] High TTL Warning: $($HighTTLRecords.Count) records have TTL > 24 hours" "INFO"
}
Write-Host " `nDNS Resolution Test:" "INFO"
try {
    # Test resolution of the zone itself
$ResolutionTest = Resolve-DnsName -Name $ZoneName -Type NS -ErrorAction SilentlyContinue
    if ($ResolutionTest) {
        Write-Host "  [OK] Zone resolution: Successful" "INFO"
        Write-Host "    Responding name servers:" "INFO"
        foreach ($NS in $ResolutionTest | Where-Object { $_.Type -eq "NS" }) {
            Write-Host "      $($NS.NameHost)" "INFO"
        }
    } else {
        Write-Host "  [FAIL] Zone resolution: Failed" "INFO"
    }
    # Test A record resolution if exists
    if ($HasA) {
$ARecordTest = Resolve-DnsName -Name $ZoneName -Type A -ErrorAction SilentlyContinue
        if ($ARecordTest) {
            Write-Host "  [OK] A record resolution: Successful" "INFO"
            foreach ($A in $ARecordTest | Where-Object { $_.Type -eq "A" }) {
                Write-Host "    $($ZoneName) -> $($A.IPAddress)" "INFO"
            }
        }
    }
} catch {
    Write-Host "  [WARN] DNS resolution test failed: $($_.Exception.Message)" "INFO"
}
Write-Host " `nRecommendations:" "INFO"
Write-Host " 1. Ensure proper TTL values for your use case" "INFO"
Write-Host " 2. Verify name server configuration at your registrar" "INFO"
Write-Host " 3. Monitor DNS query patterns and performance" "INFO"
Write-Host " 4. Consider adding health checks for critical records" "INFO"
Write-Host " 5. Implement DNS monitoring and alerting" "INFO"
Write-Host " `nDNS Zone monitoring completed at $(Get-Date)" "INFO"\n

