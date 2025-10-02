#Requires -Version 7.4

<#
.SYNOPSIS
    Installs SafeKit cluster modules from package files.

.DESCRIPTION
    This script installs SafeKit cluster modules using the SafeKit command-line tool.
    It can install from specified module packages or automatically detect .safe files.

.PARAMETER safekitcmd
    Path to the SafeKit command-line executable.

.PARAMETER MName
    Optional module name to use during installation. If not provided, derives from package filename.

.PARAMETER modulepkg
    Comma-separated list of module package files to install. If not provided, searches for .safe files.

.PARAMETER modulecfgscript
    Optional configuration script to run after module installation.

.EXAMPLE
    .\Installmodule.ps1 -safekitcmd "C:\SafeKit\safekit.exe" -MName "MyModule" -modulepkg "module1.safe,module2.safe"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$safekitcmd,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$MName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$modulepkg,

    [Parameter()]
    [string]$modulecfgscript
)

$ErrorActionPreference = "Stop"

try {
    if ($modulepkg) {
        $module = $modulepkg.Split(',') | Get-ChildItem -ErrorAction Stop
    }
    else {
        $module = [array] (Get-ChildItem -ErrorAction Stop "*.safe")
    }

    if ($module.Length) {
        $module[0] | ForEach-Object {
            if ($_) {
                if ($MName -and ($MName.Length -gt 0)) {
                    $modulename = $MName
                }
                else {
                    $modulename = $($_.Name.Replace(".safe", ""))
                }

                Write-Verbose "Installing module: $modulename from $($_.FullName)"
                & $safekitcmd module install -m $modulename $_.FullName

                if ($modulecfgscript -and (Test-Path "./$modulecfgscript")) {
                    Write-Verbose "Executing configuration script: $modulecfgscript"
                    & "./$modulecfgscript"
                }

                Write-Verbose "Enabling module: $modulename"
                & $safekitcmd -H "*" -E $modulename
            }
        }
    }
    else {
        Write-Warning "No SafeKit module packages found to install"
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}