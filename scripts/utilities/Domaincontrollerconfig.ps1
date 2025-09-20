#Requires -Version 7.0
    Domaincontrollerconfig
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
<#`n.SYNOPSIS
    PowerShell script
.DESCRIPTION
    PowerShell operation


    Author: Wes Ellis (wes@wesellis.com)
#>
PSScriptInfo
.VERSION 0.3.1
.GUID edd05043-2acc-48fa-b5b3-dab574621ba1
.AUTHOR Michael Greene
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/Microsoft/DomainControllerConfig/blob/master/LICENSE
.PROJECTURI https://github.com/Microsoft/DomainControllerConfig
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
https://github.com/Microsoft/DomainControllerConfig/blob/master/README.md#versions
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>
Demonstrates a minimally viable domain controller configuration script
compatible with Azure Automation Desired State Configuration service.
 Required variables in Automation service:
  - Credential to use for AD domain admin
  - Credential to use for Safe Mode recovery
Create these credential assets in Azure Automation,
and set their names in lines 11 and 12 of the configuration script.
Required modules in Automation service:
  - xActiveDirectory
  - xStorage
  - xPendingReboot
configuration DomainControllerConfig
{
Import-DscResource -ModuleName @{ModuleName = 'xActiveDirectory'; ModuleVersion = '2.17.0.0'}
Import-DscResource -ModuleName @{ModuleName = 'xStorage'; ModuleVersion = '3.4.0.0'}
Import-DscResource -ModuleName @{ModuleName = 'xPendingReboot'; ModuleVersion = '0.3.0.0'}
Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
$domainCredential = Get-AutomationPSCredential -ErrorAction Stop 'Credential';
$safeModeCredential = Get-AutomationPSCredential -ErrorAction Stop 'Credential'
  node localhost
  {
    WindowsFeature ADDSInstall
    {
        Ensure = 'Present'
        Name = 'AD-Domain-Services'
    }
    xWaitforDisk Disk2
    {
        DiskId = 2
        RetryIntervalSec = 10
        RetryCount = 30
    }
    xDisk DiskF
    {
        DiskId = 2
        DriveLetter = 'F'
        DependsOn = '[xWaitforDisk]Disk2'
    }
    xPendingReboot BeforeDC
    {
        Name = 'BeforeDC'
        SkipCcmClientSDK = $true
        DependsOn = '[WindowsFeature]ADDSInstall','[xDisk]DiskF'
    }
    # Configure domain values here
    xADDomain Domain
    {
        DomainName = 'contoso.local'
        DomainAdministratorCredential = $domainCredential
        SafemodeAdministratorPassword = $safeModeCredential
        DatabasePath = 'F:
TDS'
        LogPath = 'F:
TDS'
        SysvolPath = 'F:\SYSVOL'
        DependsOn = '[WindowsFeature]ADDSInstall','[xDisk]DiskF','[xPendingReboot]BeforeDC'
    }
    Registry DisableRDPNLA
    {
        Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
        ValueName = 'UserAuthentication'
        ValueData = 0
        ValueType = 'Dword'
        Ensure = 'Present'
        DependsOn = '[xADDomain]Domain'
    }
  }
}
