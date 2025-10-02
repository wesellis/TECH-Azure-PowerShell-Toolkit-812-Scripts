#Requires -Version 7.4
#Requires -Modules PSDesiredStateConfiguration

<#
.SYNOPSIS
    DSC Configuration for Active Directory Domain Controller

.DESCRIPTION
    This PowerShell DSC configuration script creates a minimally viable domain controller
    setup compatible with Azure Automation Desired State Configuration service.
    It installs AD Domain Services, configures storage, and sets up a new AD domain.

.PARAMETER DomainName
    The fully qualified domain name for the new domain (e.g., 'contoso.local')

.PARAMETER DomainCredential
    Credential for the domain administrator account

.PARAMETER SafeModeCredential
    Credential for Directory Services Restore Mode (DSRM)

.PARAMETER DatabasePath
    Path for the Active Directory database (default: 'F:\NTDS')

.PARAMETER LogPath
    Path for the Active Directory logs (default: 'F:\NTDS')

.PARAMETER SysvolPath
    Path for the SYSVOL folder (default: 'F:\SYSVOL')

.EXAMPLE
    DomainControllerConfig -DomainName "contoso.local" -DomainCredential $DomainCred -SafeModeCredential $SafeCred

.NOTES
    Required modules in Automation service:
    - ActiveDirectoryDsc (replaces deprecated xActiveDirectory)
    - StorageDsc (replaces deprecated xStorage)
    - ComputerManagementDsc (replaces deprecated xPendingReboot)

    Create credential assets in Azure Automation for domain admin and safe mode recovery.

.AUTHOR
    Original: Michael Greene (Microsoft Corporation)
    Modified: Wes Ellis (wes@wesellis.com)

.VERSION
    2.0

.GUID
    edd05043-2acc-48fa-b5b3-dab574621ba1

.TAGS
    DSCConfiguration, ActiveDirectory, DomainController

.LICENSEURI
    https://github.com/Microsoft/DomainControllerConfig/blob/master/LICENSE

.PROJECTURI
    https://github.com/Microsoft/DomainControllerConfig
#>

Configuration DomainControllerConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName = 'contoso.local',

        [Parameter()]
        [string]$DomainCredentialName = 'DomainCredential',

        [Parameter()]
        [string]$SafeModeCredentialName = 'SafeModeCredential',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$DatabasePath = 'F:\NTDS',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath = 'F:\NTDS',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SysvolPath = 'F:\SYSVOL'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName StorageDsc
    Import-DscResource -ModuleName ComputerManagementDsc

    $DomainCredential = Get-AutomationPSCredential -Name $DomainCredentialName
    $SafeModeCredential = Get-AutomationPSCredential -Name $SafeModeCredentialName

    Node localhost {
        WindowsFeature ADDSInstall {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
        }

        WindowsFeature ADDSTools {
            Ensure = 'Present'
            Name = 'RSAT-ADDS'
            DependsOn = '[WindowsFeature]ADDSInstall'
        }

        WaitForDisk Disk2 {
            DiskId = 2
            RetryIntervalSec = 10
            RetryCount = 30
        }

        Disk DiskF {
            DiskId = 2
            DriveLetter = 'F'
            DependsOn = '[WaitForDisk]Disk2'
        }

        File NTDSFolder {
            DestinationPath = $DatabasePath
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn = '[Disk]DiskF'
        }

        File SYSVOLFolder {
            DestinationPath = $SysvolPath
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn = '[Disk]DiskF'
        }

        PendingReboot BeforeDC {
            Name = 'BeforeDC'
            SkipCcmClientSDK = $true
            DependsOn = '[WindowsFeature]ADDSInstall', '[Disk]DiskF'
        }

        ADDomain Domain {
            DomainName = $DomainName
            Credential = $DomainCredential
            SafemodeAdministratorPassword = $SafeModeCredential
            DatabasePath = $DatabasePath
            LogPath = $LogPath
            SysvolPath = $SysvolPath
            DependsOn = '[WindowsFeature]ADDSInstall', '[Disk]DiskF', '[PendingReboot]BeforeDC', '[File]NTDSFolder', '[File]SYSVOLFolder'
        }

        Registry DisableRDPNLA {
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
            ValueName = 'UserAuthentication'
            ValueData = '0'
            ValueType = 'Dword'
            Ensure = 'Present'
            DependsOn = '[ADDomain]Domain'
        }

        WindowsFeature RemoteDesktop {
            Ensure = 'Present'
            Name = 'Remote-Desktop-Services'
            DependsOn = '[ADDomain]Domain'
        }

        Registry EnableRDP {
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server'
            ValueName = 'fDenyTSConnections'
            ValueData = '0'
            ValueType = 'Dword'
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]RemoteDesktop'
        }
    }
}
