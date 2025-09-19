#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Python 311

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
    We Enhanced Windows Python 311

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
Function Get-Python -ErrorAction Stop {
    $url = 'https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe'
   ;  $python = "$env:Temp\python-3.11.0-amd64.exe"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $python -UseBasicParsing
    }
    catch {
        Write-Error -Message " Failed to download python : $_.Message"
    }

    try {
        Write-WELog " Installing Python 3.11.0" " INFO"
       ;  $pythonInstallerArgs = '/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 TargetDir=C:\Python\Python311'
        Start-Process -FilePath $python -ArgumentList $pythonInstallerArgs -Wait -NoNewWindow
        Write-WELog " Completed Installing Python 3.11.0" " INFO"
    }
    catch {
        Write-Error -Message " Failed to install python  : $_.Message" -ErrorAction Stop
    }
}

Get-Python -ErrorAction Stop


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
