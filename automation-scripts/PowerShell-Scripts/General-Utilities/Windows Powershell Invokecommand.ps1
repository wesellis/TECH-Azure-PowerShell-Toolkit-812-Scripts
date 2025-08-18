<#
.SYNOPSIS
    We Enhanced Windows Powershell Invokecommand

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

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $WEScript
)
try {
    $scriptBlock = [Scriptblock]::Create($WEScript)
    Write-WELog "windows-powershell-invokecommand.ps1 will execute the following script: $scriptBlock" " INFO" 
    Invoke-Command -ScriptBlock $scriptBlock -Verbose
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================