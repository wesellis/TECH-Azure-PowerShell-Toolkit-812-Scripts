#Requires -Version 7.0

<#`n.SYNOPSIS
    Container Vs2019 Lab

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
Set-ExecutionPolicy -ErrorAction Stop Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object -ErrorAction Stop System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install docker-desktop -y
choco install git vscode -y
choco install -y visualstudio2019community --package-parameters "--allWorkloads --includeRecommended --passive --locale en-IN"
