#Requires -Version 7.4

<#`n.SYNOPSIS
    Updatedns

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Zone,
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    $name,
  $IP
  )
    $Record = Get-DnsServerResourceRecord -ZoneName $zone -Name $name
    $newrecord = $record.clone()
    $newrecord.RecordData[0].IPv4Address  =  $IP
  Set-DnsServerResourceRecord -zonename $zone -OldInputObject $record -NewInputObject $Newrecord
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
