<#
.SYNOPSIS
    Windows Msiinstaller

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory)]
    [string]$url
)
try {
$output = " $PSScriptRoot\file.msi"
    Write-Host "Downloading $url..."
    Invoke-WebRequest $url -OutFile $output
    Write-Host "Download complete."
    Write-Host "Installing $output..."
    Start-Process msiexec -ArgumentList " /i $output /qn" -Wait -NoNewWindow
    Write-Host "Installation complete."
    Remove-Item -ErrorAction Stop $outpu -Forcet -Force
} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}\n