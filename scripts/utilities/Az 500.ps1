#Requires -Version 7.4

<#
.SYNOPSIS
    Azure environment setup script for AZ-500 certification

.DESCRIPTION
    This script sets up a development environment with essential tools for Azure security
    administration and AZ-500 certification preparation. Installs Chocolatey, development tools,
    and Azure modules.

.EXAMPLE
    PS C:\> .\Az-500.ps1
    Sets up the Azure development environment

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
#>

$ErrorActionPreference = 'Stop'

# Install Chocolatey package manager
Write-Host "Installing Chocolatey..." -ForegroundColor Green
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install development tools
Write-Host "Installing development tools..." -ForegroundColor Green
choco install vscode git sql-server-management-studio -y
choco install -y visualstudio2019community --package-parameters "--allWorkloads --includeRecommended --passive --locale en-US"
choco install -y azure-cli

# Install Azure PowerShell module
Write-Host "Installing Azure PowerShell module..." -ForegroundColor Green
Install-Module Az -AllowClobber -Scope AllUsers -Force -Confirm:$false

Write-Host "Azure environment setup completed successfully!" -ForegroundColor Green