#Requires -Version 7.4

<#
.SYNOPSIS
    Install Backend MySQL Database

.DESCRIPTION
    Azure automation script that installs MySQL server and configures database for backend services

.PARAMETER MySqlRootPassword
    The root password for MySQL server

.PARAMETER MySqlUser
    The MySQL user to create

.PARAMETER MySqlUserPassword
    The password for the MySQL user

.EXAMPLE
    .\Install Backend.ps1 -MySqlRootPassword "RootPass123!" -MySqlUser "appuser" -MySqlUserPassword "UserPass123!"
    Installs MySQL with specified configuration

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MySqlRootPassword,

    [Parameter(Mandatory = $true)]
    [string]$MySqlUser,

    [Parameter(Mandatory = $true)]
    [string]$MySqlUserPassword
)

$ErrorActionPreference = 'Stop'

try {
    # Create temp directory if it doesn't exist
    if (!(Test-Path "C:\Temp")) {
        New-Item -Path "C:\Temp" -ItemType Directory -Force
    }

    Write-Output "Downloading MySQL installer..."
    $source = "http://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-5.7.11.0.msi"
    $destination = "C:\Temp\mysql.msi"

    $client = New-Object System.Net.WebClient
    $cookie = "oraclelicense=accept-securebackup-cookie"
    $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
    $client.DownloadFile($source, $destination)

    Write-Output "Installing MySQL..."
    Start-Process -Wait -FilePath msiexec -ArgumentList "/i C:\Temp\mysql.msi /quiet"

    Write-Output "Configuring MySQL server..."
    Set-Location "C:\Program Files (x86)\MySQL\MySQL Installer for Windows"

    $installCommand = "MySQLInstallerConsole.exe community install server;5.7.11;x86:*:port=3306;rootpasswd=$MySqlRootPassword;servicename=MySQL -silent"
    cmd.exe /c $installCommand

    Write-Output "Adding firewall rules..."
    $firewallRule = "netsh advfirewall firewall add rule name=`"Allow mysql`" dir=in action=allow edge=yes remoteip=any protocol=TCP localport=80,8080,3306"
    cmd.exe /c $firewallRule

    Write-Output "Configuring MySQL database and users..."
    Set-Location "C:\Program Files (x86)\MySQL\MySQL Server 5.7\bin"

    # Grant privileges to root
    $grantRootCmd = "mysql -u root -p$MySqlRootPassword -e `"grant all privileges on *.* to root@'localhost'`""
    cmd.exe /c $grantRootCmd

    # Create database
    $createDbCmd = "mysql -u root -p$MySqlRootPassword -e `"create database idp_db`""
    cmd.exe /c $createDbCmd

    # Create table
    $createTableCmd = "mysql -u root -p$MySqlRootPassword -e `"use idp_db; create table StorageRecords(context varchar(255) NOT NULL,id varchar(255) NOT NULL,expires bigint(20) DEFAULT NULL,value longtext NOT NULL,version bigint(20) NOT NULL,PRIMARY KEY(context,id))`""
    cmd.exe /c $createTableCmd

    # Create user for localhost
    $createUserLocalCmd = "mysql -u root -p$MySqlRootPassword -e `"create user $MySqlUser@'localhost' identified by '$MySqlUserPassword'`""
    cmd.exe /c $createUserLocalCmd

    # Grant privileges to user for localhost
    $grantUserLocalCmd = "mysql -u root -p$MySqlRootPassword -e `"grant all privileges on *.* to $MySqlUser@'localhost'`""
    cmd.exe /c $grantUserLocalCmd

    # Create user for any host
    $createUserAnyCmd = "mysql -u root -p$MySqlRootPassword -e `"create user $MySqlUser@'%' identified by '$MySqlUserPassword'`""
    cmd.exe /c $createUserAnyCmd

    # Grant privileges to user for any host
    $grantUserAnyCmd = "mysql -u root -p$MySqlRootPassword -e `"grant all privileges on *.* to $MySqlUser@'%'`""
    cmd.exe /c $grantUserAnyCmd

    Write-Output "Restarting MySQL service..."
    Stop-Service -Name MySQL -Force
    Start-Service -Name MySQL

    Write-Output "MySQL backend installation completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}