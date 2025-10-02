#Requires -Version 7.4

<#
.SYNOPSIS
    Install Development Tools and Environment

.DESCRIPTION
    Installs and configures a development environment including WSL, Docker Desktop,
    and various development tools via Chocolatey. Sets up user permissions and
    scheduled tasks for automatic service startup.

.PARAMETER UserName
    Username to be added to the docker-users group and used for scheduled tasks

.EXAMPLE
    .\Installscript.ps1 -UserName "john.doe"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions, internet connectivity, and Windows 10/11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName
)

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Starting development environment installation..."

    # Enable Windows features
    Write-Output "Enabling Windows Subsystem for Linux..."
    $wslFeature = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    Write-Output "WSL feature enabled (Restart needed: $($wslFeature.RestartNeeded))"

    Write-Output "Enabling Containers feature..."
    $containerFeature = Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
    Write-Output "Containers feature enabled (Restart needed: $($containerFeature.RestartNeeded))"

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
        Write-Output "Chocolatey installed successfully"
    }
    else {
        Write-Output "Chocolatey already installed"
    }

    # Create docker-users group and add user
    Write-Output "Configuring Docker user permissions..."
    try {
        $dockerGroup = Get-LocalGroup -Name "docker-users" -ErrorAction SilentlyContinue
        if (-not $dockerGroup) {
            New-LocalGroup -Name "docker-users" -Description "Users of Docker Desktop"
            Write-Output "Created docker-users group"
        }
        else {
            Write-Output "docker-users group already exists"
        }

        # Verify user exists before adding to group
        $user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
        if ($user) {
            Add-LocalGroupMember -Group 'docker-users' -Member $UserName -ErrorAction SilentlyContinue
            Write-Output "Added $UserName to docker-users group"
        }
        else {
            Write-Warning "User $UserName not found locally. Group membership may need manual configuration."
        }
    }
    catch {
        Write-Warning "Failed to configure docker-users group: $($_.Exception.Message)"
    }

    # Install development tools via Chocolatey
    Write-Output "Installing development tools..."
    $packages = @(
        'wsl-ubuntu-2204',
        'docker-desktop',
        'dbeaver',
        'mobaxterm',
        'azure-cli'
    )

    foreach ($package in $packages) {
        try {
            Write-Output "Installing $package..."
            choco install $package -y --no-progress
            Write-Output "$package installed successfully"
        }
        catch {
            Write-Warning "Failed to install ${package}: $($_.Exception.Message)"
        }
    }

    # Create scheduled task for Docker Desktop auto-start
    Write-Output "Creating Docker Desktop auto-start scheduled task..."
    try {
        $dockerExePath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerExePath) {
            $trigger = New-ScheduledTaskTrigger -AtLogOn
            $action = New-ScheduledTaskAction -Execute $dockerExePath
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

            Register-ScheduledTask -TaskName "StartDockerDesktop" -Force -Action $action -Trigger $trigger -User $UserName -Settings $settings
            Write-Output "Docker Desktop auto-start task created for user: $UserName"
        }
        else {
            Write-Warning "Docker Desktop executable not found at: $dockerExePath"
        }
    }
    catch {
        Write-Warning "Failed to create Docker Desktop scheduled task: $($_.Exception.Message)"
    }

    Write-Output "Development environment installation completed successfully"
    Write-Output "The system will now restart to complete the installation..."

    # Restart computer to apply Windows feature changes
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
catch {
    $errorMsg = "Installation script failed: $($_.Exception.Message)"
    Write-Error $errorMsg
    throw
}