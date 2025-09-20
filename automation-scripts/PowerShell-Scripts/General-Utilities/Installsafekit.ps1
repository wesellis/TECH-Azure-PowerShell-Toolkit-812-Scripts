<#
.SYNOPSIS
    Installsafekit

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
param(
    [string] $SkFile,
	[string] $Passwd
)
[CmdletBinding()]
function Log {
	[CmdletBinding()]
param(
		[string] $m
	)
	$Stamp = (Get-Date).toString(" yyyy/MM/dd HH:mm:ss" )
	Add-Content ./installsk.log " $stamp [InstallSafeKit.ps1] $m"
}
Log $vmlist
Log $modname
if( ! (Test-Path -Path " /safekit" )) {
if( ! (Test-Path -Path " $skFile" )){
   Log "Download $SkFile failed. Check calling template fileUris property."
   exit -1
}
Log "Installing ...";
$arglist = @(
    " /i" ,
    " $SkFile" ,
    " /qn" ,
    " /l*vx" ,
    " loginst.txt" ,
    "DODESKTOP='0'"
)
Start-Process msiexec.exe -ArgumentList $arglist -Wait
Log "Install Azure RM"
if(Test-Path -Path " ./installAzureRm.ps1" ) {
	& ./installAzureRm.ps1
}
Log "Applying firewall rules"
& \safekit\private\bin\firewallcfg.cmd add
Log "Starting CA helper service" ;
$cwd = Get-Location -ErrorAction Stop
try{
	cd /safekit/web/bin
	& ./startcaserv.cmd " $Passwd"
}finally{
	set-location -ErrorAction Stop $cwd
}
}
else{
	Log " safekit already installed"
}
Log " end of script"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

