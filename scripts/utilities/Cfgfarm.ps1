#Requires -Version 7.4

<#`n.SYNOPSIS
    Cfgfarm

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
	[string] $safekitcmd,
	[string] $safekitmod,
	[string] $MName
)
function Log {
	param(
		[string] $m
	)
    $Stamp = (Get-Date).toString(" yyyy/MM/dd HH:mm:ss" )
	Add-Content ./installsk.log " $stamp $m"
}
Log $safekitcmd
Log $MName
if ($MName){
    $ucfg = [Xml] (Get-Content -ErrorAction Stop " $safekitmod/$MName/conf/userconfig.xml" )
    $ucfg.safe.service.farm.lan.name=" default"
    $ucfg.Save(" $safekitmod/$MName/conf/userconfig.xml" )
	Log " $ucfg.OuterXml"
    $res = & $safekitcmd -H "*" -E $MName
	Log " ;  $MName => $res"
	& $safekitcmd -H "*" start -m $MName
}
Log " end of script"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
