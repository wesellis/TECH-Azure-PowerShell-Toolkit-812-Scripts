#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Win Slave

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Win Slave

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
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


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
