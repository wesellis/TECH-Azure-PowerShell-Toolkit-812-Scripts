#Requires -Version 7.4

<#`n.SYNOPSIS
    Setupserver

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
mkdir c:\temp -Force
Get-Date -ErrorAction Stop > c:\temp\hello.txt
dnscmd.exe /Config $args[0] /AllowUpdate 1
if ($LastExitCode -ne 0)
{
    "exit code configuring forward zone ($args[0]) was non-zero ($LastExitCode), bailing..."
    exit $LastExitCode
}
$range = $args[1]
$bits = $range.Split("/" )
$ip = $bits[0]
$net = $bits[1]
$ipbits = $ip.Split('.')
$zone = ""
switch ($net)
{
    8       { $zone = " $($ipbits[0]).in-addr.arpa." }
    16      { $zone = " $($ipbits[1]).$($ipbits[0]).in-addr.arpa." }
    24      {;  $zone = " $($ipbits[2]).$($ipbits[1]).$($ipbits[0]).in-addr.arpa." }
    default {
                Write-Warning "Vnet should be /8 /16 or /24, treating as /8"
$zone = " $($ipbits[0]).in-addr.arpa."
            }
}
dnscmd.exe /ZoneAdd $zone /DsPrimary
dnscmd.exe /Config $zone /AllowUpdate 1
if ($LastExitCode -ne 0)
{
    " exit code configuring reverse zone ($args[1]) was non-zero ($LastExitCode), bailing..."
    exit $LastExitCode`n}
