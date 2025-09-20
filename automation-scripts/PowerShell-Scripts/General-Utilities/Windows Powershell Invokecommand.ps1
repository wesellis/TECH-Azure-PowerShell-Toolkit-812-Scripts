<#
.SYNOPSIS
    Windows Powershell Invokecommand

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $Script
)
#region Functions
try {
$scriptBlock = [Scriptblock]::Create($Script)
    Write-Host " windows-powershell-invokecommand.ps1 will execute the following script: $scriptBlock"
    Invoke-Command -ScriptBlock $scriptBlock -Verbose
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}

