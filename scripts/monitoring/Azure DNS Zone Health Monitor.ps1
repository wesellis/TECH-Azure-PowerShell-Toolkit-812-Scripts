#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Dns Zone Health Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$ZoneName
)
Write-Output "Monitoring DNS Zone: $ZoneName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output " ============================================" "INFO"
    [string]$DnsZone = Get-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName
Write-Output "DNS Zone Information:" "INFO"
Write-Output "Zone Name: $($DnsZone.Name)" "INFO"
Write-Output "Resource Group: $($DnsZone.ResourceGroupName)" "INFO"
Write-Output "Number of Record Sets: $($DnsZone.NumberOfRecordSets)" "INFO"
Write-Output "Max Number of Record Sets: $($DnsZone.MaxNumberOfRecordSets)" "INFO"
Write-Output " `nName Servers:" "INFO"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Output "  $NameServer" "INFO"
}
Write-Output " `nDNS Record Sets:" "INFO"
    [string]$RecordSets = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName
    [string]$RecordSummary = $RecordSets | Group-Object RecordType
Write-Output " `nRecord Type Summary:" "INFO"
foreach ($Group in $RecordSummary) {
    Write-Output "  $($Group.Name): $($Group.Count) records" "INFO"
}
Write-Output " `n Record Sets:" "INFO"
foreach ($RecordSet in $RecordSets | Sort-Object RecordType, Name) {
    Write-Output "  - Name: $($RecordSet.Name)" "INFO"
    Write-Output "    Type: $($RecordSet.RecordType)" "INFO"
    Write-Output "    TTL: $($RecordSet.Ttl) seconds" "INFO"
    switch ($RecordSet.RecordType) {
        "A" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Ipv4Address)" "INFO"
            }
        }
        "AAAA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Ipv6Address)" "INFO"
            }
        }
        "CNAME" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Cname)" "INFO"
            }
        }
        "MX" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Preference) $($Record.Exchange)" "INFO"
            }
        }
        "NS" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Value: $($Record.Nsdname)" "INFO"
            }
        }
        "TXT" {
            foreach ($Record in $RecordSet.Records) {
    [string]$TxtValue = ($Record.Value -join ' ').Substring(0, [Math]::Min(50, ($Record.Value -join ' ').Length))
                Write-Output "    Value: $TxtValue..." "INFO"
            }
        }
        "SOA" {
            foreach ($Record in $RecordSet.Records) {
                Write-Output "    Host: $($Record.Host)" "INFO"
                Write-Output "    Email: $($Record.Email)" "INFO"
                Write-Output "    Serial: $($Record.SerialNumber)" "INFO"
                Write-Output "    Refresh: $($Record.RefreshTime)" "INFO"
                Write-Output "    Retry: $($Record.RetryTime)" "INFO"
                Write-Output "    Expire: $($Record.ExpireTime)" "INFO"
                Write-Output "    Minimum TTL: $($Record.MinimumTtl)" "INFO"
            }
        }
    }
    Write-Output "    ---" "INFO"
}
Write-Output " `nDNS Health Checks:" "INFO"
    [string]$HasSOA = $RecordSets | Where-Object { $_.RecordType -eq "SOA" -and $_.Name -eq " @" }
    [string]$HasNS = $RecordSets | Where-Object { $_.RecordType -eq "NS" -and $_.Name -eq " @" }
    [string]$HasA = $RecordSets | Where-Object { $_.RecordType -eq "A" -and $_.Name -eq " @" }
    [string]$HasWWW = $RecordSets | Where-Object { $_.Name -eq " www" }
Write-Output "  [OK] SOA Record: $(if ($HasSOA) { 'Present' } else { 'Missing' })" "INFO"
Write-Output "  [OK] NS Records: $(if ($HasNS) { 'Present' } else { 'Missing' })" "INFO"
Write-Output "  [OK] Root A Record: $(if ($HasA) { 'Present' } else { 'Missing (Optional)' })" "INFO"
Write-Output "  [OK] WWW Record: $(if ($HasWWW) { 'Present' } else { 'Missing (Recommended)' })" "INFO"
    [string]$LowTTLRecords = $RecordSets | Where-Object { $_.Ttl -lt 300 -and $_.RecordType -ne "SOA" }
if ($LowTTLRecords.Count -gt 0) {
    Write-Output "  [WARN] Low TTL Warning: $($LowTTLRecords.Count) records have TTL < 5 minutes" "INFO"
    foreach ($Record in $LowTTLRecords) {
        Write-Output "    - $($Record.Name) ($($Record.RecordType)): $($Record.Ttl)s" "INFO"
    }
}
    [string]$HighTTLRecords = $RecordSets | Where-Object { $_.Ttl -gt 86400 -and $_.RecordType -ne "SOA" -and $_.RecordType -ne "NS" }
if ($HighTTLRecords.Count -gt 0) {
    Write-Output "  [WARN] High TTL Warning: $($HighTTLRecords.Count) records have TTL > 24 hours" "INFO"
}
Write-Output " `nDNS Resolution Test:" "INFO"
try {
    [string]$ResolutionTest = Resolve-DnsName -Name $ZoneName -Type NS -ErrorAction SilentlyContinue
    if ($ResolutionTest) {
        Write-Output "  [OK] Zone resolution: Successful" "INFO"
        Write-Output "    Responding name servers:" "INFO"
        foreach ($NS in $ResolutionTest | Where-Object { $_.Type -eq "NS" }) {
            Write-Output "      $($NS.NameHost)" "INFO"
        }
    } else {
        Write-Output "  [FAIL] Zone resolution: Failed" "INFO"
    }
    if ($HasA) {
    [string]$ARecordTest = Resolve-DnsName -Name $ZoneName -Type A -ErrorAction SilentlyContinue
        if ($ARecordTest) {
            Write-Output "  [OK] A record resolution: Successful" "INFO"
            foreach ($A in $ARecordTest | Where-Object { $_.Type -eq "A" }) {
                Write-Output "    $($ZoneName) -> $($A.IPAddress)" "INFO"
            }
        }
    }
} catch {
    Write-Output "  [WARN] DNS resolution test failed: $($_.Exception.Message)" "INFO"
}
Write-Output " `nRecommendations:" "INFO"
Write-Output " 1. Ensure proper TTL values for your use case" "INFO"
Write-Output " 2. Verify name server configuration at your registrar" "INFO"
Write-Output " 3. Monitor DNS query patterns and performance" "INFO"
Write-Output " 4. Consider adding health checks for critical records" "INFO"
Write-Output " 5. Implement DNS monitoring and alerting" "INFO"
Write-Output " `nDNS Zone monitoring completed at $(Get-Date)" "INFO"



