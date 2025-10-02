#Requires -Version 7.4

<#
.SYNOPSIS
    Chocolatey Package Installer

.DESCRIPTION
    Installs Chocolatey package manager and specified packages on Windows systems.
    This script bypasses UAC and installs packages with elevated privileges.

.PARAMETER ChocoPackages
    Semicolon-separated list of Chocolatey packages to install

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    WARNING: This script disables UAC and should be used with caution
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ChocoPackages
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    Write-Output "Installing Chocolatey packages: $ChocoPackages"

    Write-Verbose "Setting execution policy for process"
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

    Write-Verbose "Configuring security protocol"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    Write-Output "Installing Chocolatey package manager..."
    $installScript = {
        Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    Invoke-Command -ScriptBlock $installScript

    Write-Warning "Disabling UAC (User Account Control) - this is a security risk"
    $uacScript = {
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLua -Value 0
    }
    Invoke-Command -ScriptBlock $uacScript

    Write-Output "Installing packages..."
    $packageList = $ChocoPackages.Split(";")

    foreach ($package in $packageList) {
        $package = $package.Trim()
        if ($package) {
            Write-Output "Installing package: $package"
            choco install $package -y -force
            Write-Verbose "Successfully installed: $package"
        }
    }

    Write-Output "All packages from choco.org were installed successfully"
    Write-Warning "Remember to restart the system for UAC changes to take effect"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}