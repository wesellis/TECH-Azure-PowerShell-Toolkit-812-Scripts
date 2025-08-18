<#
.SYNOPSIS
    Setupserver

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
    We Enhanced Setupserver

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


mkdir c:\temp -Force
Get-Date -ErrorAction Stop > c:\temp\hello.txt


dnscmd.exe /Config $args[0] /AllowUpdate 1
if ($WELastExitCode -ne 0)
{
    "exit code configuring forward zone ($args[0]) was non-zero ($WELastExitCode), bailing..."
    exit $WELastExitCode
}


$range = $args[1]
$bits = $range.Split(" /" )
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
                Write-Warning " Vnet should be /8 /16 or /24, treating as /8"
               ;  $zone = " $($ipbits[0]).in-addr.arpa." 
            }
}
dnscmd.exe /ZoneAdd $zone /DsPrimary
dnscmd.exe /Config $zone /AllowUpdate 1
if ($WELastExitCode -ne 0)
{
    " exit code configuring reverse zone ($args[1]) was non-zero ($WELastExitCode), bailing..."
    exit $WELastExitCode
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================