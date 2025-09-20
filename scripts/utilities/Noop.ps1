#Requires -Version 7.0

<#`n.SYNOPSIS
    Noop

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    [String] $DBDataLUNS = " 0,1,2" ,
    [String] $DBLogLUNS = " 3" ,
    [string] $DBDataDrive = "S:" ,
    [string] $DBLogDrive = "L:" ,
    [string] $DBDataName = " dbdata" ,
    [string];  $DBLogName = " dblog"
)
#region Functions
[CmdletBinding()]
function Log
{
	[CmdletBinding()]
param(
		[string] $message
	)
$message = (Get-Date).ToString() + " : " + $message;
	Write-Host $message;
	if (-not (Test-Path (" c:" + [char]92 + " sapcd" )))
	{
		$nul = mkdir (" c:" + [char]92 + " sapcd" );
	}
	$message | Out-File -Append -FilePath (" c:" + [char]92 + " sapcd" + [char]92 + " log.txt" );
}
Log " noop"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
