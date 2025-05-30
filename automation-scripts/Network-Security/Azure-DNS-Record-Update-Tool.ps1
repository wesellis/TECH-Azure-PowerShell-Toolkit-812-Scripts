# ============================================================================
# Script Name: Azure DNS Record Update Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Updates Azure DNS records with new values and TTL settings
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ZoneName,
    [string]$RecordSetName,
    [string]$RecordType,
    [int]$TTL,
    [string]$RecordValue
)

# Get the existing record set
$RecordSet = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName -Name $RecordSetName -RecordType $RecordType

Write-Host "Updating DNS Record: $RecordSetName.$ZoneName"
Write-Host "Record Type: $RecordType"
Write-Host "Current TTL: $($RecordSet.Ttl)"
Write-Host "New TTL: $TTL"
Write-Host "New Value: $RecordValue"

# Update TTL
$RecordSet.Ttl = $TTL

# Update record value based on type
switch ($RecordType) {
    "A" { 
        $RecordSet.Records.Clear()
        $RecordSet.Records.Add((New-AzDnsRecordConfig -IPv4Address $RecordValue))
    }
    "CNAME" { 
        $RecordSet.Records.Clear()
        $RecordSet.Records.Add((New-AzDnsRecordConfig -Cname $RecordValue))
    }
    "TXT" { 
        $RecordSet.Records.Clear()
        $RecordSet.Records.Add((New-AzDnsRecordConfig -Value $RecordValue))
    }
}

# Apply the changes
Set-AzDnsRecordSet -RecordSet $RecordSet

Write-Host "DNS record updated successfully"
