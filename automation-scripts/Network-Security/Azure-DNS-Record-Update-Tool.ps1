#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$ZoneName,
    [string]$RecordSetName,
    [string]$RecordType,
    [int]$TTL,
    [string]$RecordValue
)

#region Functions

# Get the existing record set
$RecordSet = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName -Name $RecordSetName -RecordType $RecordType

Write-Information "Updating DNS Record: $RecordSetName.$ZoneName"
Write-Information "Record Type: $RecordType"
Write-Information "Current TTL: $($RecordSet.Ttl)"
Write-Information "New TTL: $TTL"
Write-Information "New Value: $RecordValue"

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

Write-Information "DNS record updated successfully"


#endregion
