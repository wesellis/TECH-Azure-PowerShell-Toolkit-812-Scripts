<#
.SYNOPSIS
    Updatedns

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Updatedns

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEZone,
  [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$name,
  [string]$WEIP
  )
 ;  $WERecord = Get-DnsServerResourceRecord -ZoneName $zone -Name $name
 ;  $newrecord = $record.clone()
  $newrecord.RecordData[0].IPv4Address  =  $WEIP
  Set-DnsServerResourceRecord -zonename $zone -OldInputObject $record -NewInputObject $WENewrecord



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
