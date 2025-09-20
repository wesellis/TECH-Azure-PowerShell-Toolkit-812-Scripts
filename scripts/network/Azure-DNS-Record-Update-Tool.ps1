#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage DNS

.DESCRIPTION
    Manage DNS
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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

