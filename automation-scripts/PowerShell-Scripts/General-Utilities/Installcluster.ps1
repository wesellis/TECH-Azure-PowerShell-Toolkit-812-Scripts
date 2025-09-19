#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Installcluster

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Installcluster

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
	[string] $publicipfmt,
	[string] $privateiplist,
    [string] $vmlist,
	[string] $lblist,
	[string] $WEPasswd
)

#region Functions

$targetDir = " ."

[CmdletBinding()]
function WE-Log {
	[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
		[string] $m
	)

; 	$WEStamp = (Get-Date).toString(" yyyy/MM/dd HH:mm:ss" )
	Add-Content ./installsk.log " $stamp [installCluster.ps1] $m" 
}

Log $vmlist 
Log $publicipfmt
Log $privateiplist

$env:SAFEBASE=" /safekit"	
$env:SAFEKITCMD=" /safekit/safekit.exe"
$env:SAFEVAR=" /safekit/var"
$env:SAFEWEBCONF=" /safekit/web/conf"
	
& ./configCluster.ps1 -vmlist $vmlist -publicipfmt $publicipfmt -privateiplist $privateiplist -lblist $lblist -Passwd $WEPasswd

Log " end of script"





} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
