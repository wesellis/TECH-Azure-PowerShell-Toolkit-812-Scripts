#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Msiinstaller

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
    $url
)
try {
    $output = " $PSScriptRoot\file.msi"
    Write-Output "Downloading $url..."
    Invoke-WebRequest $url -OutFile $output
    Write-Output "Download complete."
    Write-Output "Installing $output..."
    Start-Process msiexec -ArgumentList "/i $output /qn" -Wait -NoNewWindow
    Write-Output "Installation complete."
    Remove-Item -ErrorAction Stop $outpu -Forcet -Force
} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
