#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Add To Path

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
    [Parameter(Mandatory = $true)]
    $NewPath
)
try {
    Write-Output "Adding '$NewPath' to system's Path environment variable"
    if ($NewPath.Contains(" ;" )) {
        Write-Output "WARNING: Cannot add path that contains ';' (semicolon) to system's Path environment variable"
        Write-Output "Not making any changes"
        exit 0
    }
    $path = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $PathPieces = $path -split " ;"
    if ($NewPath -in $PathPieces) {
        Write-Output "Path already contains '$NewPath'. Not making any changes."
    }
    else {
    $ModifiedPath = $path + " ;" + $NewPath
        [Environment]::SetEnvironmentVariable("Path" , $ModifiedPath, 'Machine')
        Write-Output " '$NewPath' added to system's Path environment variable"

} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
