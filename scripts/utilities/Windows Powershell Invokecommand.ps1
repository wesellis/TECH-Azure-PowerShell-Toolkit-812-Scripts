#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Powershell Invokecommand

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
try {
    $ScriptBlock = [Scriptblock]::Create($Script)
    Write-Output " windows-powershell-invokecommand.ps1 will execute the following script: $ScriptBlock"
    Invoke-Command -ScriptBlock $ScriptBlock -Verbose
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
