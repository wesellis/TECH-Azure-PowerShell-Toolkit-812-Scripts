#Requires -Version 7.4

<#`n.SYNOPSIS
    Win Slave

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Set-ExecutionPolicy -ErrorAction Stop Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object -ErrorAction Stop System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y jdk8 maven git
choco install microsoft-build-tools -y
choco install -y dotnetcore-sdk
cd \
wget -outFile sonar.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.2.0.1873-windows.zip
Expand-Archive -Path sonar.zip -DestinationPath .
Ren -path sonar-scanner-cli-4.2.0.1873-windows -NewName sonar
del sonar.zip


