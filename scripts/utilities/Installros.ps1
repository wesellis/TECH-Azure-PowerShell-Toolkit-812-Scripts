#Requires -Version 7.4

<#
.SYNOPSIS
    Install ROS (Robot Operating System)

.DESCRIPTION
    Installs Robot Operating System packages using Chocolatey package manager.
    Sets up multiple ROS distributions including Melodic, Noetic, and Foxy.
    Configures WinRM for remote management with HTTPS.

.PARAMETER SkipWinRM
    Skip WinRM configuration setup

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions and internet connectivity
#>

[CmdletBinding()]
param(
    [switch]$SkipWinRM
)

$ErrorActionPreference = 'Stop'

try {
    # Install Chocolatey if not already installed
    Write-Output "Installing Chocolatey package manager..."
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        $currentPolicy = Get-ExecutionPolicy
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
        finally {
            Set-ExecutionPolicy $currentPolicy -Scope Process -Force
        }
    }
    else {
        Write-Output "Chocolatey already installed"
    }

    # Add ROS Windows package source
    Write-Output "Adding ROS Windows package source..."
    $existingSource = choco source list | Select-String "ros-win"
    if (-not $existingSource) {
        choco source add -n=ros-win -s="https://aka.ms/ros/public" --priority=1
    }
    else {
        Write-Output "ROS Windows source already exists"
    }

    # Install ROS distributions
    Write-Output "Installing ROS Melodic Desktop Full..."
    choco upgrade ros-melodic-desktop_full -y --execution-timeout=0

    Write-Output "Installing ROS Noetic Desktop Full..."
    choco upgrade ros-noetic-desktop_full -y --execution-timeout=0

    Write-Output "Installing ROS Foxy Desktop..."
    choco upgrade ros-foxy-desktop -y --execution-timeout=0

    # Configure WinRM if not skipped
    if (-not $SkipWinRM) {
        Write-Output "Configuring WinRM for remote management..."

        # Enable PowerShell Remoting
        try {
            Enable-PSRemoting -Force -SkipNetworkProfileCheck
            Write-Output "PowerShell Remoting enabled"
        }
        catch {
            Write-Warning "Failed to enable PowerShell Remoting: $($_.Exception.Message)"
        }

        # Create firewall rule for WinRM HTTPS
        $existingRule = Get-NetFirewallRule -Name "Allow WinRM HTTPS" -ErrorAction SilentlyContinue
        if (-not $existingRule) {
            New-NetFirewallRule -Name "Allow WinRM HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 5986 -Protocol TCP
            Write-Output "WinRM HTTPS firewall rule created"
        }
        else {
            Write-Output "WinRM HTTPS firewall rule already exists"
        }

        # Create self-signed certificate for HTTPS
        try {
            $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
            $thumbprint = $cert.Thumbprint

            # Configure WinRM HTTPS listener
            $command = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`"$env:computername`"; CertificateThumbprint=`"$thumbprint`"}"
            cmd.exe /C $command

            Write-Output "WinRM HTTPS listener configured with certificate thumbprint: $thumbprint"
        }
        catch {
            Write-Warning "Failed to configure WinRM HTTPS listener: $($_.Exception.Message)"
        }
    }
    else {
        Write-Output "Skipping WinRM configuration as requested"
    }

    # Set machine ID for telemetry (optional)
    try {
        $localDeviceIdPath = "HKLM:\SOFTWARE\Microsoft\SQMClient"
        $localDeviceIdName = "MachineId"
        $localDeviceIdValue = "{df713376-9b62-46d6-a363-cede5b1bf2c5}"

        if (-not (Test-Path $localDeviceIdPath)) {
            New-Item -Path $localDeviceIdPath -Force | Out-Null
        }

        New-ItemProperty -Path $localDeviceIdPath -Name $localDeviceIdName -Value $localDeviceIdValue -PropertyType String -Force | Out-Null
        Write-Output "Machine ID configured for telemetry"
    }
    catch {
        Write-Warning "Failed to set machine ID: $($_.Exception.Message)"
    }

    Write-Output "ROS installation completed successfully"
    Write-Output "Installed distributions: ROS Melodic, ROS Noetic, ROS Foxy"
}
catch {
    Write-Error "ROS installation failed: $($_.Exception.Message)"
    throw
}