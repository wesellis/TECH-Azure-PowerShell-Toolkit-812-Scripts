#Requires -Version 7.4

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
    $packages,
    [Parameter()]
    [bool]$AddToPath=$true
)
try {
    $PackageArray = $packages.split(" ," )
    $NpmPrefix = "C:
pm"
    npm config set prefix $NpmPrefix
    for ($i = 0; $i -lt $PackageArray.count; $i++) {
    $package = $PackageArray[$i].trim()
        Write-Output "Installing $package globally"
        npm install -g $package
        Write-Output "Installation complete"
    }
    if ($AddToPath) {
        Write-Output "Adding npm prefix to PATH"
	[Environment]::SetEnvironmentVariable("PATH" , $env:Path + " ;$NpmPrefix" , "Machine" )
        Write-Output " npm prefix added to PATH"
    }
} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
