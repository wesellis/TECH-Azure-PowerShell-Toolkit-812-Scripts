#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Cfgmirror

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
    We Enhanced Cfgmirror

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
	[string] $safekitcmd,
	[string] $safekitmod,
	[string] $WEMName
)

#region Functions



[CmdletBinding()]
function WE-Log {
	[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
		[string] $m
	)

	$WEStamp = (Get-Date).toString(" yyyy/MM/dd HH:mm:ss" )
	Add-Content ./installsk.log " $stamp $m" 
}

Log $safekitcmd 
Log $WEMName

$repdir = " $env:systemdrive/replicated"

if ($WEMName){

	$ucfg = [Xml] (Get-Content -ErrorAction Stop " $safekitmod/$WEMName/conf/userconfig.xml" )
	$ucfg.safe.service.heart.heartbeat.name=" default"
	[xml]$rfsconf=" <rfs><replicated dir='$repdir'/></rfs>"
	$ucfg.safe.service.AppendChild($ucfg.ImportNode($rfsconf.rfs,$true))

	$ucfg.Save(" $safekitmod/$WEMName/conf/userconfig.xml" )
	Log " $ucfg.OuterXml"
	

	
; 	$res = & $safekitcmd -H " *" -E $WEMName
	Log " ;  $WEMName => $res"
	& $safekitcmd prim -m $WEMName
	& $safekitcmd -H " VM2" start -m $WEMName
}

Log " end of script"





} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
