#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Dns Record Update Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
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
[CmdletBinding()];
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

$RecordSet = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName -Name $RecordSetName -RecordType $RecordType
Write-Host "Updating DNS Record: $RecordSetName.$ZoneName" "INFO"
Write-Host "Record Type: $RecordType" "INFO"
Write-Host "Current TTL: $($RecordSet.Ttl)" "INFO"
Write-Host "New TTL: $TTL" "INFO"
Write-Host "New Value: $RecordValue" "INFO"
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
Write-Host "DNS record updated successfully" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

