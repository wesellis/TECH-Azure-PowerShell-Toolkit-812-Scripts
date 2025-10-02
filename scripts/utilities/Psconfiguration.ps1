#Requires -Version 7.4
#Requires -Modules TemplateHelpDSC

<#
.SYNOPSIS
    Primary Site Server Configuration for SCCM

.DESCRIPTION
    Azure DSC configuration for SCCM Primary Site server setup.
    Configures domain join, SQL services, features, and SCCM prerequisites.

.PARAMETER DomainName
    Active Directory domain name

.PARAMETER DCName
    Domain controller name

.PARAMETER DPMPName
    DPMP server name

.PARAMETER CSName
    Central Site server name

.PARAMETER PSName
    Primary Site server name

.PARAMETER ClientName
    Array of client names

.PARAMETER Configuration
    Configuration type (Standalone or Hierarchy)

.PARAMETER DNSIPAddress
    DNS server IP address

.PARAMETER Admincreds
    Domain administrator credentials

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and DSC modules
    Part of SCCM infrastructure deployment
#>

Configuration PSConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [String]$DomainName,

        [Parameter(Mandatory = $true)]
        [String]$DCName,

        [Parameter(Mandatory = $true)]
        [String]$DPMPName,

        [Parameter(Mandatory = $true)]
        [String]$CSName,

        [Parameter(Mandatory = $true)]
        [String]$PSName,

        [Parameter(Mandatory = $true)]
        [System.Array]$ClientName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Standalone", "Hierarchy")]
        [String]$Configuration,

        [Parameter(Mandatory = $true)]
        [String]$DNSIPAddress,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -ModuleName TemplateHelpDSC

    # Configuration variables
    $LogFolder = "TempLog"
    $CM = "CMCB"
    $LogPath = "C:\$LogFolder"
    $DName = $DomainName.Split(".")[0]
    $DCComputerAccount = "$DName\$DCName$"
    $CurrentRole = "PS"

    if ($Configuration -ne "Standalone") {
        $CSComputerAccount = "$DName\$CSName$"
    }

    $DPMPComputerAccount = "$DName\$DPMPName$"
    $Clients = [System.String]::Join(",", $ClientName)

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential(
        "${DomainName}\$($Admincreds.UserName)",
        $Admincreds.Password
    )

    Node LOCALHOST {
        LocalConfigurationManager {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        # Configure page file
        SetCustomPagingFile PagingSettings {
            Drive = 'C:'
            InitialSize = '8192'
            MaximumSize = '8192'
        }

        # Add SQL permissions
        AddBuiltinPermission AddSQLPermission {
            Ensure = "Present"
            DependsOn = "[SetCustomPagingFile]PagingSettings"
        }

        # Install SCCM features
        InstallFeatureForSCCM InstallFeature {
            NAME = "PS"
            Role = "Site Server"
            DependsOn = "[AddBuiltinPermission]AddSQLPermission"
        }

        # Install ADK
        InstallADK ADKInstall {
            ADKPath = "C:\adksetup.exe"
            ADKWinPEPath = "C:\adksetupwinpe.exe"
            Ensure = "Present"
            DependsOn = "[InstallFeatureForSCCM]InstallFeature"
        }

        # Install Visual C++ Redistributables
        DownloadAndInstallvcredist DownloadAndInstallvcredist {
            Ensure = "Present"
            DependsOn = "[InstallADK]ADKInstall"
        }

        # Install ODBC driver
        DownloadAndInstallODBC DownloadAndInstallODBC {
            Ensure = "Present"
            DependsOn = "[DownloadAndInstallvcredist]DownloadAndInstallvcredist"
        }

        # Configure DNS
        SetDNS DnsServerAddress {
            DNSIPAddress = $DNSIPAddress
            Ensure = "Present"
            DependsOn = "[DownloadAndInstallODBC]DownloadAndInstallODBC"
        }

        # Wait for domain to be ready
        WaitForDomainReady WaitForDomain {
            Ensure = "Present"
            DCName = $DCName
            WaitSeconds = 0
            DependsOn = "[SetDNS]DnsServerAddress"
        }

        # Join domain
        JoinDomain JoinDomain {
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[WaitForDomainReady]WaitForDomain"
        }

        # Create share folder
        File ShareFolder {
            DestinationPath = $LogPath
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn = "[JoinDomain]JoinDomain"
        }

        # Open firewall ports
        OpenFirewallPortForSCCM OpenFirewall {
            Name = "PS"
            Role = "Site Server"
            DependsOn = "[JoinDomain]JoinDomain"
        }

        # Wait for delegation control
        WaitForConfigurationFile DelegateControl {
            Role = "DC"
            MachineName = $DCName
            LogFolder = $LogFolder
            ReadNode = "DelegateControl"
            Ensure = "Present"
            DependsOn = "[OpenFirewallPortForSCCM]OpenFirewall"
        }

        # Change SQL service account
        ChangeSQLServicesAccount ChangeToLocalSystem {
            SQLInstanceName = "MSSQLSERVER"
            Ensure = "Present"
            DependsOn = "[WaitForConfigurationFile]DelegateControl"
        }

        if ($Configuration -eq "Standalone") {
            # Standalone configuration
            DownloadSCCM DownLoadSCCM {
                CM = $CM
                Ensure = "Present"
                DependsOn = "[DownloadAndInstallODBC]DownloadAndInstallODBC"
            }

            FileReadAccessShare DomainSMBShare {
                Name = $LogFolder
                Path = $LogPath
                Account = $DCComputerAccount
                DependsOn = "[File]ShareFolder"
            }

            FileReadAccessShare CMSourceSMBShare {
                Name = $CM
                Path = "C:\$CM"
                Account = $DCComputerAccount
                DependsOn = "[ChangeSQLServicesAccount]ChangeToLocalSystem"
            }

            RegisterTaskScheduler InstallAndUpdateSCCM {
                TaskName = "ScriptWorkFlow"
                ScriptName = "ScriptWorkFlow.ps1"
                ScriptPath = $PSScriptRoot
                ScriptArgument = "$DomainName $CM $DName\$($Admincreds.UserName) $DPMPName $Clients $Configuration $CurrentRole $LogFolder $CSName $PSName"
                Ensure = "Present"
                DependsOn = "[FileReadAccessShare]CMSourceSMBShare"
            }
        }
        else {
            # Hierarchy configuration
            WaitForConfigurationFile WaitCSJoinDomain {
                Role = "DC"
                MachineName = $DCName
                LogFolder = $LogFolder
                ReadNode = "CSJoinDomain"
                Ensure = "Present"
                DependsOn = "[File]ShareFolder"
            }

            FileReadAccessShare DomainSMBShare {
                Name = $LogFolder
                Path = $LogPath
                Account = @($DCComputerAccount, $CSComputerAccount)
                DependsOn = "[WaitForConfigurationFile]WaitCSJoinDomain"
            }

            RegisterTaskScheduler InstallAndUpdateSCCM {
                TaskName = "ScriptWorkFlow"
                ScriptName = "ScriptWorkFlow.ps1"
                ScriptPath = $PSScriptRoot
                ScriptArgument = "$DomainName $CM $DName\$($Admincreds.UserName) $DPMPName $Clients $Configuration $CurrentRole $LogFolder $CSName $PSName"
                Ensure = "Present"
                DependsOn = "[ChangeSQLServicesAccount]ChangeToLocalSystem"
            }
        }
    }
}

# Example usage:
# PSConfiguration -DomainName 'contoso.com' -DCName 'DC01' -DPMPName 'DPMP01' -CSName 'CS01' -PSName 'PS01' -ClientName @('Client01', 'Client02') -Configuration 'Standalone' -DNSIPAddress '10.0.0.4' -Admincreds $adminCred
# Start-DscConfiguration -Path .\PSConfiguration -Wait -Verbose -Force