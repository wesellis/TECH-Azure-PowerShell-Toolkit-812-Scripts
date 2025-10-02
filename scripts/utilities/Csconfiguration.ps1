#Requires -Version 7.4

<#
.SYNOPSIS
    CS Configuration DSC Script

.DESCRIPTION
    Azure automation DSC configuration for Central Site (CS) server setup.
    This configuration sets up a Central Site server for System Center Configuration Manager.

.PARAMETER DomainName
    The domain name for the configuration

.PARAMETER DCName
    The domain controller name

.PARAMETER DPMPName
    The DPMP server name

.PARAMETER CSName
    The Central Site server name

.PARAMETER PSName
    The Primary Site server name

.PARAMETER ClientName
    Array of client names

.PARAMETER Configuration
    The configuration type

.PARAMETER DNSIPAddress
    The DNS IP address

.PARAMETER Admincreds
    Administrator credentials

.NOTES
    Version: 1.0
    Author: Wes Ellis (wes@wesellis.com)
    Requires appropriate permissions and modules
    DSC Configuration for Central Site setup
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'The domain name for the configuration')]
    [String]$DomainName,

    [Parameter(Mandatory = $true, HelpMessage = 'The domain controller name')]
    [String]$DCName,

    [Parameter(Mandatory = $true, HelpMessage = 'The DPMP server name')]
    [String]$DPMPName,

    [Parameter(Mandatory = $true, HelpMessage = 'The Central Site server name')]
    [String]$CSName,

    [Parameter(Mandatory = $true, HelpMessage = 'The Primary Site server name')]
    [String]$PSName,

    [Parameter(Mandatory = $true, HelpMessage = 'Array of client names')]
    [System.Array]$ClientName,

    [Parameter(Mandatory = $true, HelpMessage = 'The configuration type')]
    [String]$Configuration,

    [Parameter(Mandatory = $true, HelpMessage = 'The DNS IP address')]
    [String]$DNSIPAddress,

    [Parameter(Mandatory = $true, HelpMessage = 'Administrator credentials')]
    [System.Management.Automation.PSCredential]$Admincreds
)

$ErrorActionPreference = "Stop"

try {
    configuration Configuration {
        Import-DscResource -ModuleName TemplateHelpDSC

        $LogFolder = "TempLog"
        $CM = "CMCB"
        $LogPath = "c:\$LogFolder"
        $DName = $DomainName.Split(".")[0]
        $DCComputerAccount = "$DName\$DCName$"
        $PSComputerAccount = "$DName\$PSName$"
        $DPMPComputerAccount = "$DName\$DPMPName$"
        [String]$Clients = [system.String]::Join(",", $ClientName)
        $CurrentRole = "CS"
        $PrimarySiteName = $PSName.split(".")[0] + "$"
        [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

        Node LOCALHOST {
            LocalConfigurationManager {
                ConfigurationMode = 'ApplyOnly'
                RebootNodeIfNeeded = $true
            }

            SetCustomPagingFile PagingSettings {
                Drive       = 'C:'
                InitialSize = '8192'
                MaximumSize = '8192'
            }

            AddBuiltinPermission AddSQLPermission {
                Ensure = "Present"
                DependsOn = "[SetCustomPagingFile]PagingSettings"
            }

            InstallFeatureForSCCM InstallFeature {
                NAME = "CS"
                Role = "Site Server"
                DependsOn = "[AddBuiltinPermission]AddSQLPermission"
            }

            InstallADK ADKInstall {
                ADKPath = "C:\adksetup.exe"
                ADKWinPEPath = "c:\adksetupwinpe.exe"
                Ensure = "Present"
                DependsOn = "[InstallFeatureForSCCM]InstallFeature"
            }

            DownloadAndInstallODBC DownloadAndInstallODBC {
                Ensure = "Present"
                DependsOn = "[InstallADK]ADKInstall"
            }

            DownloadSCCM DownLoadSCCM {
                CM = $CM
                Ensure = "Present"
                DependsOn = "[DownloadAndInstallODBC]DownloadAndInstallODBC"
            }

            SetDNS DnsServerAddress {
                DNSIPAddress = $DNSIPAddress
                Ensure = "Present"
                DependsOn = "[DownloadSCCM]DownLoadSCCM"
            }

            WaitForDomainReady WaitForDomain {
                Ensure = "Present"
                DCName = $DCName
                WaitSeconds = 0
                DependsOn = "[SetDNS]DnsServerAddress"
            }

            JoinDomain JoinDomain {
                DomainName = $DomainName
                Credential = $DomainCreds
                DependsOn = "[WaitForDomainReady]WaitForDomain"
            }

            File ShareFolder {
                DestinationPath = $LogPath
                Type = 'Directory'
                Ensure = 'Present'
                DependsOn = "[JoinDomain]JoinDomain"
            }

            WaitForConfigurationFile WaitPSJoinDomain {
                Role = "DC"
                MachineName = $DCName
                LogFolder = $LogFolder
                ReadNode = "PSJoinDomain"
                Ensure = "Present"
                DependsOn = "[File]ShareFolder"
            }

            FileReadAccessShare DomainSMBShare {
                Name = $LogFolder
                Path = $LogPath
                Account = $DCComputerAccount, $PSComputerAccount
                DependsOn = "[WaitForConfigurationFile]WaitPSJoinDomain"
            }

            OpenFirewallPortForSCCM OpenFirewall {
                Name = "CS"
                Role = "Site Server"
                DependsOn = "[JoinDomain]JoinDomain"
            }

            WaitForConfigurationFile DelegateControl {
                Role = "DC"
                MachineName = $DCName
                LogFolder = $LogFolder
                ReadNode = "DelegateControl"
                Ensure = "Present"
                DependsOn = "[OpenFirewallPortForSCCM]OpenFirewall"
            }

            ChangeSQLServicesAccount ChangeToLocalSystem {
                SQLInstanceName = "MSSQLSERVER"
                Ensure = "Present"
                DependsOn = "[WaitForConfigurationFile]DelegateControl"
            }

            FileReadAccessShare CMSourceSMBShare {
                Name = $CM
                Path = "c:\$CM"
                Account = $DCComputerAccount
                DependsOn = "[ChangeSQLServicesAccount]ChangeToLocalSystem"
            }

            AddUserToLocalAdminGroup AddADComputerToLocalAdminGroup {
                Name = "$PrimarySiteName"
                DomainName = $DomainName
                DependsOn = "[FileReadAccessShare]CMSourceSMBShare"
            }

            RegisterTaskScheduler InstallAndUpdateSCCM {
                TaskName = "ScriptWorkFlow"
                ScriptName = "ScriptWorkFlow.ps1"
                ScriptPath = $PSScriptRoot
                ScriptArgument = "$DomainName $CM $DName\$($Admincreds.UserName) $DPMPName $Clients $Configuration $CurrentRole $LogFolder $CSName $PSName"
                Ensure = "Present"
                DependsOn = "[AddUserToLocalAdminGroup]AddADComputerToLocalAdminGroup"
            }
        }
    }

    Write-Output "DSC Configuration completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}