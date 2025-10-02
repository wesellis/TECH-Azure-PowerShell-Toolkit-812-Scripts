#Requires -Version 7.4
#Requires -Modules TemplateHelpDSC

<#
.SYNOPSIS
    Client Configuration DSC

.DESCRIPTION
    Azure DSC configuration for client machines to join domain and configure for SCCM

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

configuration ClientConfiguration
{
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
        [String]$Configuration,

        [Parameter(Mandatory = $true)]
        [String]$DNSIPAddress,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    Import-DscResource -ModuleName TemplateHelpDSC

    $LogFolder = "TempLog"
    $LogPath = "c:\$LogFolder"
    $DName = $DomainName.Split(".")[0]
    $DCComputerAccount = "$DName\$DCName$"
    $PSComputerAccount = "$DName\$PSName$"
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $PrimarySiteName = $PSName.Split(".")[0] + "$"

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        SetCustomPagingFile PagingSettings
        {
            Drive       = 'C:'
            InitialSize = '8192'
            MaximumSize = '8192'
        }

        SetDNS DnsServerAddress
        {
            DNSIPAddress = $DNSIPAddress
            Ensure = "Present"
            DependsOn = "[SetCustomPagingFile]PagingSettings"
        }

        InstallFeatureForSCCM InstallFeature
        {
            Name = "Client"
            Role = "Client"
            DependsOn = "[SetCustomPagingFile]PagingSettings"
        }

        WaitForDomainReady WaitForDomain
        {
            Ensure = "Present"
            DCName = $DCName
            DependsOn = "[SetDNS]DnsServerAddress"
        }

        JoinDomain JoinDomain
        {
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[WaitForDomainReady]WaitForDomain"
        }

        WaitForConfigurationFile WaitForPSJoinDomain
        {
            Role = "DC"
            MachineName = $DCName
            LogFolder = $LogFolder
            ReadNode = "PSJoinDomain"
            Ensure = "Present"
            DependsOn = "[JoinDomain]JoinDomain"
        }

        File ShareFolder
        {
            DestinationPath = $LogPath
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn = "[WaitForConfigurationFile]WaitForPSJoinDomain"
        }

        FileReadAccessShare DomainSMBShare
        {
            Name = $LogFolder
            Path = $LogPath
            Account = $DCComputerAccount,$PSComputerAccount
            DependsOn = "[File]ShareFolder"
        }

        OpenFirewallPortForSCCM OpenFirewall
        {
            Name = "Client"
            Role = "Client"
            DependsOn = "[JoinDomain]JoinDomain"
        }

        AddUserToLocalAdminGroup AddADUserToLocalAdminGroup
        {
            Name = $($Admincreds.UserName)
            DomainName = $DomainName
            DependsOn = "[FileReadAccessShare]DomainSMBShare"
        }

        AddUserToLocalAdminGroup AddADComputerToLocalAdminGroup
        {
            Name = $PrimarySiteName
            DomainName = $DomainName
            DependsOn = "[FileReadAccessShare]DomainSMBShare"
        }

        WriteConfigurationFile WriteClientFinished
        {
            Role = "Client"
            LogPath = $LogPath
            WriteNode = "ClientFinished"
            Status = "Passed"
            Ensure = "Present"
            DependsOn = "[AddUserToLocalAdminGroup]AddADUserToLocalAdminGroup","[AddUserToLocalAdminGroup]AddADComputerToLocalAdminGroup"
        }
    }
}