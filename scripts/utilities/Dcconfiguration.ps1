#Requires -Version 7.4

<#
.SYNOPSIS
    DC Configuration DSC Script

.DESCRIPTION
    Azure automation DSC configuration for Domain Controller (DC) setup.
    This configuration sets up a domain controller for System Center Configuration Manager.

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
    The configuration type (Standalone or other)

.PARAMETER DNSIPAddress
    The DNS IP address

.PARAMETER Admincreds
    Administrator credentials

.NOTES
    Version: 1.0
    Author: Wes Ellis (wes@wesellis.com)
    Requires appropriate permissions and modules
    DSC Configuration for Domain Controller setup
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
        $LogPath = "c:\$LogFolder"
        $CM = "CMCB"
        $DName = $DomainName.Split(".")[0]

        if ($Configuration -ne "Standalone") {
            $CSComputerAccount = "$DName\$CSName$"
        }
        $PSComputerAccount = "$DName\$PSName$"
        $DPMPComputerAccount = "$DName\$DPMPName$"
        $Clients = [system.String]::Join(",", $ClientName)
        $ClientComputerAccount = "$DName\$Clients$"
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

            InstallFeatureForSCCM InstallFeature {
                Name = 'DC'
                Role = 'DC'
                DependsOn = "[SetCustomPagingFile]PagingSettings"
            }

            SetupDomain FirstDS {
                DomainFullName = $DomainName
                SafemodeAdministratorPassword = $DomainCreds
                DependsOn = "[InstallFeatureForSCCM]InstallFeature"
            }

            InstallCA InstallCA {
                HashAlgorithm = "SHA256"
                DependsOn = "[SetupDomain]FirstDS"
            }

            VerifyComputerJoinDomain WaitForPS {
                ComputerName = $PSName
                Ensure = "Present"
                DependsOn = "[InstallCA]InstallCA"
            }

            VerifyComputerJoinDomain WaitForDPMP {
                ComputerName = $DPMPName
                Ensure = "Present"
                DependsOn = "[InstallCA]InstallCA"
            }

            VerifyComputerJoinDomain WaitForClient {
                ComputerName = $Clients
                Ensure = "Present"
                DependsOn = "[InstallCA]InstallCA"
            }

            if ($Configuration -eq 'Standalone') {
                File ShareFolder {
                    DestinationPath = $LogPath
                    Type = 'Directory'
                    Ensure = 'Present'
                    DependsOn = @("[VerifyComputerJoinDomain]WaitForPS", "[VerifyComputerJoinDomain]WaitForDPMP", "[VerifyComputerJoinDomain]WaitForClient")
                }

                FileReadAccessShare DomainSMBShare {
                    Name = $LogFolder
                    Path = $LogPath
                    Account = $PSComputerAccount, $DPMPComputerAccount, $ClientComputerAccount
                    DependsOn = "[File]ShareFolder"
                }

                WriteConfigurationFile WriteDelegateControlfinished {
                    Role = "DC"
                    LogPath = $LogPath
                    WriteNode = "DelegateControl"
                    Status = "Passed"
                    Ensure = "Present"
                    DependsOn = @("[DelegateControl]AddPS", "[DelegateControl]AddDPMP")
                }

                WaitForExtendSchemaFile WaitForExtendSchemaFile {
                    MachineName = $PSName
                    ExtFolder = $CM
                    Ensure = "Present"
                    DependsOn = "[WriteConfigurationFile]WriteDelegateControlfinished"
                }
            }
            else {
                VerifyComputerJoinDomain WaitForCS {
                    ComputerName = $CSName
                    Ensure = "Present"
                    DependsOn = "[InstallCA]InstallCA"
                }

                File ShareFolder {
                    DestinationPath = $LogPath
                    Type = 'Directory'
                    Ensure = 'Present'
                    DependsOn = @("[VerifyComputerJoinDomain]WaitForCS", "[VerifyComputerJoinDomain]WaitForPS", "[VerifyComputerJoinDomain]WaitForDPMP", "[VerifyComputerJoinDomain]WaitForClient")
                }

                FileReadAccessShare DomainSMBShare {
                    Name = $LogFolder
                    Path = $LogPath
                    Account = $CSComputerAccount, $PSComputerAccount, $DPMPComputerAccount, $ClientComputerAccount
                    DependsOn = "[File]ShareFolder"
                }

                WriteConfigurationFile WriteCSJoinDomain {
                    Role = "DC"
                    LogPath = $LogPath
                    WriteNode = "CSJoinDomain"
                    Status = "Passed"
                    Ensure = "Present"
                    DependsOn = "[FileReadAccessShare]DomainSMBShare"
                }

                DelegateControl AddCS {
                    Machine = $CSName
                    DomainFullName = $DomainName
                    Ensure = "Present"
                    DependsOn = "[WriteConfigurationFile]WriteCSJoinDomain"
                }

                WriteConfigurationFile WriteDelegateControlfinished {
                    Role = "DC"
                    LogPath = $LogPath
                    WriteNode = "DelegateControl"
                    Status = "Passed"
                    Ensure = "Present"
                    DependsOn = @("[DelegateControl]AddCS", "[DelegateControl]AddPS", "[DelegateControl]AddDPMP")
                }

                WaitForExtendSchemaFile WaitForExtendSchemaFile {
                    MachineName = $CSName
                    ExtFolder = $CM
                    Ensure = "Present"
                    DependsOn = "[WriteConfigurationFile]WriteDelegateControlfinished"
                }
            }

            WriteConfigurationFile WritePSJoinDomain {
                Role = "DC"
                LogPath = $LogPath
                WriteNode = "PSJoinDomain"
                Status = "Passed"
                Ensure = "Present"
                DependsOn = "[FileReadAccessShare]DomainSMBShare"
            }

            WriteConfigurationFile WriteDPMPJoinDomain {
                Role = "DC"
                LogPath = $LogPath
                WriteNode = "DPMPJoinDomain"
                Status = "Passed"
                Ensure = "Present"
                DependsOn = "[FileReadAccessShare]DomainSMBShare"
            }

            WriteConfigurationFile WriteClientJoinDomain {
                Role = "DC"
                LogPath = $LogPath
                WriteNode = "ClientJoinDomain"
                Status = "Passed"
                Ensure = "Present"
                DependsOn = "[FileReadAccessShare]DomainSMBShare"
            }

            DelegateControl AddPS {
                Machine = $PSName
                DomainFullName = $DomainName
                Ensure = "Present"
                DependsOn = "[WriteConfigurationFile]WritePSJoinDomain"
            }

            DelegateControl AddDPMP {
                Machine = $DPMPName
                DomainFullName = $DomainName
                Ensure = "Present"
                DependsOn = "[WriteConfigurationFile]WriteDPMPJoinDomain"
            }
        }
    }

    Write-Output "DSC Configuration completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}