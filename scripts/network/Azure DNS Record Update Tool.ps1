#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Dns Record Update Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
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
;
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ZoneName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RecordSetName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RecordType,
    [int]$TTL,
    [string]$RecordValue
)
    [string]$RecordSet = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName -Name $RecordSetName -RecordType $RecordType
Write-Output "Updating DNS Record: $RecordSetName.$ZoneName" "INFO"
Write-Output "Record Type: $RecordType" "INFO"
Write-Output "Current TTL: $($RecordSet.Ttl)" "INFO"
Write-Output "New TTL: $TTL" "INFO"
Write-Output "New Value: $RecordValue" "INFO"
    [string]$RecordSet.Ttl = $TTL
switch ($RecordType) {
    "A" {
    [string]$RecordSet.Records.Clear()
    [string]$RecordSet.Records.Add((New-AzDnsRecordConfig -IPv4Address $RecordValue))
    }
    "CNAME" {
    [string]$RecordSet.Records.Clear()
    [string]$RecordSet.Records.Add((New-AzDnsRecordConfig -Cname $RecordValue))
    }
    "TXT" {
    [string]$RecordSet.Records.Clear()
    [string]$RecordSet.Records.Add((New-AzDnsRecordConfig -Value $RecordValue))
    }
}
Set-AzDnsRecordSet -RecordSet $RecordSet
Write-Output "DNS record updated successfully" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
