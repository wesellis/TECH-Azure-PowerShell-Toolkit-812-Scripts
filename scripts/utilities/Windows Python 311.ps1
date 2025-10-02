#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Python 311

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
Function Get-Python -ErrorAction Stop {
    $url = 'https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe'
$python = "$env:Temp\python-3.11.0-amd64.exe"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $python -UseBasicParsing
    }
    catch {
        Write-Error -Message "Failed to download python : $_.Message"
    }
    try {
        Write-Output "Installing Python 3.11.0"
$PythonInstallerArgs = '/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 TargetDir=C:\Python\Python311'
        Start-Process -FilePath $python -ArgumentList $PythonInstallerArgs -Wait -NoNewWindow
        Write-Output "Completed Installing Python 3.11.0"
    }
    catch {
        Write-Error -Message "Failed to install python  : $_.Message" -ErrorAction Stop
    }
}
Get-Python -ErrorAction Stop



