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
    [string]$RecordSetName,
    [string]$RecordType,
    [int]$TTL,
    [string]$RecordValue
)
$RecordSet = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName -Name $RecordSetName -RecordType $RecordType
Write-Output "Updating DNS Record: $RecordSetName.$ZoneName"
Write-Output "Record Type: $RecordType"
Write-Output "Current TTL: $($RecordSet.Ttl)"
Write-Output "New TTL: $TTL"
Write-Output "New Value: $RecordValue"
$RecordSet.Ttl = $TTL
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
Set-AzDnsRecordSet -RecordSet $RecordSet
Write-Output "DNS record updated successfully"



