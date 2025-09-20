#Requires -Version 7.0

<#`n.SYNOPSIS
    Windows Npm Global

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$packages,
    [Parameter()]
    [bool]$addToPath=$true
)
try {
$packageArray = $packages.split(" ," )
$npmPrefix = "C:
pm"
    npm config set prefix $npmPrefix
    for ($i = 0; $i -lt $packageArray.count; $i++) {
        $package = $packageArray[$i].trim()
        Write-Host "Installing $package globally"
        npm install -g $package
        Write-Host "Installation complete"
    }
    if ($addToPath) {
        Write-Host "Adding npm prefix to PATH"
	[Environment]::SetEnvironmentVariable("PATH" , $env:Path + " ;$npmPrefix" , "Machine" )
        Write-Host " npm prefix added to PATH"
    }
} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}
