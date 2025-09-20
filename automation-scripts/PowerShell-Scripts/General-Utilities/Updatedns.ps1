<#
.SYNOPSIS
    Updatedns

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Zone,
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$name,
  [string]$IP
  )
$Record = Get-DnsServerResourceRecord -ZoneName $zone -Name $name
$newrecord = $record.clone()
  $newrecord.RecordData[0].IPv4Address  =  $IP
  Set-DnsServerResourceRecord -zonename $zone -OldInputObject $record -NewInputObject $Newrecord
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

