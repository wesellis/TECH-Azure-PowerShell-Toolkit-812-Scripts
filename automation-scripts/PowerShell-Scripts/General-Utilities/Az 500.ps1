<#
.SYNOPSIS
    Az 500

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Set-ExecutionPolicy -ErrorAction Stop Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object -ErrorAction Stop System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install vscode git sql-server-management-studio -y
choco install -y visualstudio2019community --package-parameters "--allWorkloads --includeRecommended --passive --locale en-IN"
choco install -y azure-cli
install-module Az -AllowClobber -Scope AllUsers -Force -Confirm

