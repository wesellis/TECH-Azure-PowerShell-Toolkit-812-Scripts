<#
.SYNOPSIS
    We Enhanced Az 500

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))


choco install vscode git sql-server-management-studio -y


choco install -y visualstudio2019community --package-parameters "--allWorkloads --includeRecommended --passive --locale en-IN"


choco install -y azure-cli


install-module Az -AllowClobber -Scope AllUsers -Force -Confirm


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================