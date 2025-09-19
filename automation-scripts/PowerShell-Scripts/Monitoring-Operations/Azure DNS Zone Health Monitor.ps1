#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Dns Zone Health Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Dns Zone Health Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WEZoneName
)

#region Functions

Write-WELog " Monitoring DNS Zone: $WEZoneName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WEDnsZone = Get-AzDnsZone -ResourceGroupName $WEResourceGroupName -Name $WEZoneName

Write-WELog " DNS Zone Information:" " INFO"
Write-WELog "  Zone Name: $($WEDnsZone.Name)" " INFO"
Write-WELog "  Resource Group: $($WEDnsZone.ResourceGroupName)" " INFO"
Write-WELog "  Number of Record Sets: $($WEDnsZone.NumberOfRecordSets)" " INFO"
Write-WELog "  Max Number of Record Sets: $($WEDnsZone.MaxNumberOfRecordSets)" " INFO"


Write-WELog " `nName Servers:" " INFO"
foreach ($WENameServer in $WEDnsZone.NameServers) {
    Write-WELog "  $WENameServer" " INFO"
}


Write-WELog " `nDNS Record Sets:" " INFO"
$WERecordSets = Get-AzDnsRecordSet -ResourceGroupName $WEResourceGroupName -ZoneName $WEZoneName


$WERecordSummary = $WERecordSets | Group-Object RecordType
Write-WELog " `nRecord Type Summary:" " INFO"
foreach ($WEGroup in $WERecordSummary) {
    Write-WELog "  $($WEGroup.Name): $($WEGroup.Count) records" " INFO"
}


Write-WELog " `nDetailed Record Sets:" " INFO"
foreach ($WERecordSet in $WERecordSets | Sort-Object RecordType, Name) {
    Write-WELog "  - Name: $($WERecordSet.Name)" " INFO"
    Write-WELog "    Type: $($WERecordSet.RecordType)" " INFO"
    Write-WELog "    TTL: $($WERecordSet.Ttl) seconds" " INFO"
    
    # Display records based on type
    switch ($WERecordSet.RecordType) {
        " A" {
            foreach ($WERecord in $WERecordSet.Records) {
                Write-WELog "    Value: $($WERecord.Ipv4Address)" " INFO"
            }
        }
        " AAAA" {
            foreach ($WERecord in $WERecordSet.Records) {
                Write-WELog "    Value: $($WERecord.Ipv6Address)" " INFO"
            }
        }
        " CNAME" {
            foreach ($WERecord in $WERecordSet.Records) {
                Write-WELog "    Value: $($WERecord.Cname)" " INFO"
            }
        }
        " MX" {
            foreach ($WERecord in $WERecordSet.Records) {
                Write-WELog "    Value: $($WERecord.Preference) $($WERecord.Exchange)" " INFO"
            }
        }
        " NS" {
            foreach ($WERecord in $WERecordSet.Records) {
                Write-WELog "    Value: $($WERecord.Nsdname)" " INFO"
            }
        }
        " TXT" {
            foreach ($WERecord in $WERecordSet.Records) {
                $WETxtValue = ($WERecord.Value -join ' ').Substring(0, [Math]::Min(50, ($WERecord.Value -join ' ').Length))
                Write-WELog "    Value: $WETxtValue..." " INFO"
            }
        }
        " SOA" {
            foreach ($WERecord in $WERecordSet.Records) {
                Write-WELog "    Host: $($WERecord.Host)" " INFO"
                Write-WELog "    Email: $($WERecord.Email)" " INFO"
                Write-WELog "    Serial: $($WERecord.SerialNumber)" " INFO"
                Write-WELog "    Refresh: $($WERecord.RefreshTime)" " INFO"
                Write-WELog "    Retry: $($WERecord.RetryTime)" " INFO"
                Write-WELog "    Expire: $($WERecord.ExpireTime)" " INFO"
                Write-WELog "    Minimum TTL: $($WERecord.MinimumTtl)" " INFO"
            }
        }
    }
    Write-WELog "    ---" " INFO"
}


Write-WELog " `nDNS Health Checks:" " INFO"


$WEHasSOA = $WERecordSets | Where-Object { $_.RecordType -eq " SOA" -and $_.Name -eq " @" }
$WEHasNS = $WERecordSets | Where-Object { $_.RecordType -eq " NS" -and $_.Name -eq " @" }
$WEHasA = $WERecordSets | Where-Object { $_.RecordType -eq " A" -and $_.Name -eq " @" }
$WEHasWWW = $WERecordSets | Where-Object { $_.Name -eq " www" }

Write-WELog "  [OK] SOA Record: $(if ($WEHasSOA) { 'Present' } else { 'Missing' })" " INFO"
Write-WELog "  [OK] NS Records: $(if ($WEHasNS) { 'Present' } else { 'Missing' })" " INFO"
Write-WELog "  [OK] Root A Record: $(if ($WEHasA) { 'Present' } else { 'Missing (Optional)' })" " INFO"
Write-WELog "  [OK] WWW Record: $(if ($WEHasWWW) { 'Present' } else { 'Missing (Recommended)' })" " INFO"


$WELowTTLRecords = $WERecordSets | Where-Object { $_.Ttl -lt 300 -and $_.RecordType -ne " SOA" }
if ($WELowTTLRecords.Count -gt 0) {
    Write-WELog "  [WARN] Low TTL Warning: $($WELowTTLRecords.Count) records have TTL < 5 minutes" " INFO"
    foreach ($WERecord in $WELowTTLRecords) {
        Write-WELog "    - $($WERecord.Name) ($($WERecord.RecordType)): $($WERecord.Ttl)s" " INFO"
    }
}

$WEHighTTLRecords = $WERecordSets | Where-Object { $_.Ttl -gt 86400 -and $_.RecordType -ne " SOA" -and $_.RecordType -ne " NS" }
if ($WEHighTTLRecords.Count -gt 0) {
    Write-WELog "  [WARN] High TTL Warning: $($WEHighTTLRecords.Count) records have TTL > 24 hours" " INFO"
}


Write-WELog " `nDNS Resolution Test:" " INFO"
try {
    # Test resolution of the zone itself
   ;  $WEResolutionTest = Resolve-DnsName -Name $WEZoneName -Type NS -ErrorAction SilentlyContinue
    if ($WEResolutionTest) {
        Write-WELog "  [OK] Zone resolution: Successful" " INFO"
        Write-WELog "    Responding name servers:" " INFO"
        foreach ($WENS in $WEResolutionTest | Where-Object { $_.Type -eq " NS" }) {
            Write-WELog "      $($WENS.NameHost)" " INFO"
        }
    } else {
        Write-WELog "  [FAIL] Zone resolution: Failed" " INFO"
    }
    
    # Test A record resolution if exists
    if ($WEHasA) {
       ;  $WEARecordTest = Resolve-DnsName -Name $WEZoneName -Type A -ErrorAction SilentlyContinue
        if ($WEARecordTest) {
            Write-WELog "  [OK] A record resolution: Successful" " INFO"
            foreach ($WEA in $WEARecordTest | Where-Object { $_.Type -eq " A" }) {
                Write-WELog "    $($WEZoneName) -> $($WEA.IPAddress)" " INFO"
            }
        }
    }
    
} catch {
    Write-WELog "  [WARN] DNS resolution test failed: $($_.Exception.Message)" " INFO"
}

Write-WELog " `nRecommendations:" " INFO"
Write-WELog " 1. Ensure proper TTL values for your use case" " INFO"
Write-WELog " 2. Verify name server configuration at your registrar" " INFO"
Write-WELog " 3. Monitor DNS query patterns and performance" " INFO"
Write-WELog " 4. Consider adding health checks for critical records" " INFO"
Write-WELog " 5. Implement DNS monitoring and alerting" " INFO"

Write-WELog " `nDNS Zone monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
