#Requires -Version 7.0

<#`n.SYNOPSIS
    Qs Bootstrap

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$adminUser = $Args[0]
$adminPassword = $Args[1]
$scriptUrl = $($Args[10]);
$password =  Read-Host -Prompt "Enter secure value" -AsSecureString;
$credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential -ArgumentList $env:computername\$adminUser, $password
New-Item -ItemType directory -Path C:\installation
copy-item ".\qs-install.ps1" " c:\installation\"
Enable-PSRemoting -Force
Invoke-Command -ScriptBlock { & c:\installation\qs-install.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $($Args[5]) $($Args[6]) $($Args[7]) $($Args[8]) $($Args[9]) } -ArgumentList ($Args[0], $Args[1], $Args[2], $Args[3], $Args[4], $($Args[5]), $($Args[6]), $($Args[7]), $($Args[8]), $($Args[9])) -Credential $credential -ComputerName $env:COMPUTERNAME
Disable-PSRemoting -Force
