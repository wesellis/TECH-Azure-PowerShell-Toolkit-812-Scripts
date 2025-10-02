#Requires -Version 7.4

<#
.SYNOPSIS
    Configures Data Protection Manager Point (DPMP) for SCCM.

.DESCRIPTION
    This PowerShell DSC configuration script sets up a Distribution Point and Management Point
    for Microsoft System Center Configuration Manager (SCCM). It configures the system to join
    a domain, installs required features, and sets up proper permissions.

.PARAMETER DomainName
    The name of the Active Directory domain to join.

.PARAMETER DCName
    The name of the Domain Controller.

.PARAMETER DPMPName
    The name of the Distribution Point/Management Point server.

.PARAMETER CSName
    The name of the Configuration Server.

.PARAMETER PSName
    The name of the Primary Site server.

.PARAMETER ClientName
    Array of client machine names.

.PARAMETER Configuration
    The configuration type to apply.

.PARAMETER DNSIPAddress
    The IP address of the DNS server.

.PARAMETER Admincreds
    Administrator credentials for domain operations.

.EXAMPLE
    Configuration -DomainName "contoso.com" -DCName "DC01" -DPMPName "DPMP01" -CSName "CS01" -PSName "PS01" -ClientName @("Client01","Client02") -Configuration "Standard" -DNSIPAddress "192.168.1.10" -Admincreds $creds

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Requires TemplateHelpDSC module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$DomainName,

    [Parameter(Mandatory)]
    [String]$DCName,

    [Parameter(Mandatory)]
    [String]$DPMPName,

    [Parameter(Mandatory)]
    [String]$CSName,

    [Parameter(Mandatory)]
    [String]$PSName,

    [Parameter(Mandatory)]
    [System.Array]$ClientName,

    [Parameter(Mandatory)]
    [String]$Configuration,

    [Parameter(Mandatory)]
    [String]$DNSIPAddress,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Admincreds
)

$ErrorActionPreference = "Stop"

try {
    configuration DPMPConfiguration {
        param(
            [Parameter(Mandatory)]
            [String]$DomainName,

            [Parameter(Mandatory)]
            [String]$DCName,

            [Parameter(Mandatory)]
            [String]$DPMPName,

            [Parameter(Mandatory)]
            [String]$CSName,

            [Parameter(Mandatory)]
            [String]$PSName,

            [Parameter(Mandatory)]
            [System.Array]$ClientName,

            [Parameter(Mandatory)]
            [String]$Configuration,

            [Parameter(Mandatory)]
            [String]$DNSIPAddress,

            [Parameter(Mandatory)]
            [System.Management.Automation.PSCredential]$Admincreds
        )

        Import-DscResource -ModuleName TemplateHelpDSC

        $LogFolder = "TempLog"
        $LogPath = "C:\$LogFolder"
        $DName = $DomainName.Split(".")[0]
        $DCComputerAccount = "$DName\$DCName$"
        $PSComputerAccount = "$DName\$PSName$"
        [System.Management.Automation.PSCredential]$DomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
        $PrimarySiteName = $PSName.split(".")[0] + "$"

        Node localhost {
            LocalConfigurationManager {
                ConfigurationMode = 'ApplyOnly'
                RebootNodeIfNeeded = $true
            }

            SetCustomPagingFile PagingSettings {
                Drive       = 'C:'
                InitialSize = '8192'
                MaximumSize = '8192'
            }

            SetDNS DnsServerAddress {
                DNSIPAddress = $DNSIPAddress
                Ensure = "Present"
                DependsOn = "[SetCustomPagingFile]PagingSettings"
            }

            InstallFeatureForSCCM InstallFeature {
                Name = "DPMP"
                Role = "Distribution Point", "Management Point"
                DependsOn = "[SetCustomPagingFile]PagingSettings"
            }

            WaitForDomainReady WaitForDomain {
                Ensure = "Present"
                DCName = $DCName
                DependsOn = "[SetDNS]DnsServerAddress"
            }

            JoinDomain JoinDomain {
                DomainName = $DomainName
                Credential = $DomainCreds
                DependsOn = "[WaitForDomainReady]WaitForDomain"
            }

            WaitForConfigurationFile WaitForPSJoinDomain {
                Role = "DC"
                MachineName = $DCName
                LogFolder = $LogFolder
                ReadNode = "PSJoinDomain"
                Ensure = "Present"
                DependsOn = "[JoinDomain]JoinDomain"
            }

            File ShareFolder {
                DestinationPath = $LogPath
                Type = 'Directory'
                Ensure = 'Present'
                DependsOn = "[WaitForConfigurationFile]WaitForPSJoinDomain"
            }

            FileReadAccessShare DomainSMBShare {
                Name = $LogFolder
                Path = $LogPath
                Account = $DCComputerAccount, $PSComputerAccount
                DependsOn = "[File]ShareFolder"
            }

            OpenFirewallPortForSCCM OpenFirewall {
                Name = "DPMP"
                Role = "Distribution Point", "Management Point"
                DependsOn = "[JoinDomain]JoinDomain"
            }

            AddUserToLocalAdminGroup AddADUserToLocalAdminGroup {
                Name = $($Admincreds.UserName)
                DomainName = $DomainName
                DependsOn = "[FileReadAccessShare]DomainSMBShare"
            }

            AddUserToLocalAdminGroup AddADComputerToLocalAdminGroup {
                Name = "$PrimarySiteName"
                DomainName = $DomainName
                DependsOn = "[FileReadAccessShare]DomainSMBShare"
            }

            WriteConfigurationFile WriteDPMPFinished {
                Role = "DPMP"
                LogPath = $LogPath
                WriteNode = "DPMPFinished"
                Status = "Passed"
                Ensure = "Present"
                DependsOn = "[AddUserToLocalAdminGroup]AddADUserToLocalAdminGroup", "[AddUserToLocalAdminGroup]AddADComputerToLocalAdminGroup"
            }
        }
    }

    # Generate the configuration
    DPMPConfiguration -DomainName $DomainName -DCName $DCName -DPMPName $DPMPName -CSName $CSName -PSName $PSName -ClientName $ClientName -Configuration $Configuration -DNSIPAddress $DNSIPAddress -Admincreds $Admincreds

    Write-Output "DPMP Configuration generated successfully"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}