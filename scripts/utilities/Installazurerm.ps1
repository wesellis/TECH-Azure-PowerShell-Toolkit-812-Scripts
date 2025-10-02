#Requires -Version 7.4

<#
.SYNOPSIS
    Install Azure PowerShell modules

.DESCRIPTION
    Azure automation script that installs the modern Az PowerShell modules (replacing deprecated AzureRM)

.PARAMETER Linux
    Switch parameter to specify if running on Linux platform

.EXAMPLE
    .\Installazurerm.ps1
    Installs Azure PowerShell modules for Windows

.EXAMPLE
    .\Installazurerm.ps1 -Linux
    Installs Azure PowerShell modules for Linux

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrator privileges
    Note: Updated to use Az modules instead of deprecated AzureRM
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Linux = $false
)

$ErrorActionPreference = "Stop"

try {
    if ($Linux) {
        Write-Output "Installing Azure PowerShell for Linux..."
        Install-Module Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    }
    else {
        Write-Output "Installing NuGet package provider..."
        Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force

        Write-Output "Installing Azure PowerShell for Windows..."
        Install-Module Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    }

    Write-Output "Azure PowerShell modules installed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}