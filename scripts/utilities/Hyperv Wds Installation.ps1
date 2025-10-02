#Requires -Version 7.4

<#
.SYNOPSIS
    Hyperv Wds Installation

.DESCRIPTION
    Azure automation for installing Hyper-V and Microsoft Deployment Toolkit (MDT) with WDS configuration

.PARAMETER None
    This script does not accept parameters

.EXAMPLE
    .\Hyperv Wds Installation.ps1
    Installs Hyper-V and Microsoft Deployment Toolkit

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrator privileges and appropriate Windows features
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Write-Output "Installing Hyper-V..."
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

Write-Output "Configuring firewall rules for Hyper-V..."
Set-NetFirewallRule -Name "Remote Desktop - User Mode (TCP-In)" -Enabled True
Set-NetFirewallRule -Name "Remote Desktop - User Mode (UDP-In)" -Enabled True
Set-NetFirewallRule -Name "Remote Event Log Management (RPC)" -Enabled True

Write-Output "Downloading Microsoft Deployment Toolkit..."
$mdtInstallerPath = "C:\Temp\MDT\MicrosoftDeploymentToolkit_x64.msi"
$mdtInstallerUrl = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi"
$mdtInstallerFolder = Split-Path $mdtInstallerPath -Parent

if (!(Test-Path $mdtInstallerFolder)) {
    Write-Output "Creating directory $mdtInstallerFolder..."
    New-Item -Path $mdtInstallerFolder -ItemType Directory
}

Invoke-WebRequest -Uri $mdtInstallerUrl -OutFile $mdtInstallerPath

Write-Output "Installing Microsoft Deployment Toolkit..."
Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$mdtInstallerPath`" /qn" -Wait

Write-Output "Configuring firewall rules for Microsoft Deployment Toolkit..."
New-NetFirewallRule -DisplayName "MDT Deployment Share" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow

Write-Output "Restarting the computer..."
Restart-Computer -Force