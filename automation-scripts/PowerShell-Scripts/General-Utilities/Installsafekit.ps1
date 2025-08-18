<#
.SYNOPSIS
    Installsafekit

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
    We Enhanced Installsafekit

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
param(
    [string] $WESkFile,
	[string] $WEPasswd
)

[CmdletBinding()]
function WE-Log {
	[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
		[string] $m
	)

	$WEStamp = (Get-Date).toString(" yyyy/MM/dd HH:mm:ss" )
	Add-Content ./installsk.log " $stamp [InstallSafeKit.ps1] $m" 
}

Log $vmlist 
Log $modname
	
if( ! (Test-Path -Path " /safekit" )) {

if( ! (Test-Path -Path " $skFile" )){

   Log " Download $WESkFile failed. Check calling template fileUris property."
   exit -1
}

Log " Installing ..."; 
$arglist = @(
    " /i" ,
    " $WESkFile" ,
    " /qn" ,
    " /l*vx" ,
    " loginst.txt" ,
    " DODESKTOP='0'"
)

Start-Process msiexec.exe -ArgumentList $arglist -Wait
Log " Install Azure RM"

if(Test-Path -Path " ./installAzureRm.ps1" ) {
	& ./installAzureRm.ps1
}

Log " Applying firewall rules"
& \safekit\private\bin\firewallcfg.cmd add

Log " Starting CA helper service" ; 
$cwd = Get-Location -ErrorAction Stop
try{
	cd /safekit/web/bin
	& ./startcaserv.cmd " $WEPasswd"
}finally{
	set-location -ErrorAction Stop $cwd
}	

}
else{
	Log " safekit already installed"
}
Log " end of script"





} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
