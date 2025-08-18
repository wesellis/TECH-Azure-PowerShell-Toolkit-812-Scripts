<#
.SYNOPSIS
    Dpmpconfiguration

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Dpmpconfiguration

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿configuration Configuration
{
   [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
        [Parameter(Mandatory)]
        [String]$WEDomainName,
        [Parameter(Mandatory)]
        [String]$WEDCName,
        [Parameter(Mandatory)]
        [String]$WEDPMPName,
        [Parameter(Mandatory)]
        [String]$WECSName,
        [Parameter(Mandatory)]
        [String]$WEPSName,
        [Parameter(Mandatory)]
        [System.Array]$WEClientName,
        [Parameter(Mandatory)]
        [String]$WEConfiguration,
        [Parameter(Mandatory)]
        [String]$WEDNSIPAddress,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds
    )

    Import-DscResource -ModuleName TemplateHelpDSC

    $WELogFolder = " TempLog"
    $WELogPath = " c:\$WELogFolder"
    $WEDName = $WEDomainName.Split(" ." )[0]
    $WEDCComputerAccount = " $WEDName\$WEDCName$"
   ;  $WEPSComputerAccount = " $WEDName\$WEPSName$"

    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)
   ;  $WEPrimarySiteName = $WEPSName.split(" ." )[0] + " $"

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
            DNSIPAddress = $WEDNSIPAddress
            Ensure = " Present"
            DependsOn = " [SetCustomPagingFile]PagingSettings"
        }

        InstallFeatureForSCCM InstallFeature
        {
            Name = " DPMP"
            Role = " Distribution Point" ," Management Point"
            DependsOn = " [SetCustomPagingFile]PagingSettings"
        }

        WaitForDomainReady WaitForDomain
        {
            Ensure = " Present"
            DCName = $WEDCName
            DependsOn = " [SetDNS]DnsServerAddress"
        }

        JoinDomain JoinDomain
        {
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            DependsOn = " [WaitForDomainReady]WaitForDomain"
        }

        WaitForConfigurationFile WaitForPSJoinDomain
        {
            Role = " DC"
            MachineName = $WEDCName
            LogFolder = $WELogFolder
            ReadNode = " PSJoinDomain"
            Ensure = " Present"
            DependsOn = " [JoinDomain]JoinDomain"
        }

        File ShareFolder
        {            
            DestinationPath = $WELogPath     
            Type = 'Directory'            
            Ensure = 'Present'
            DependsOn = " [WaitForConfigurationFile]WaitForPSJoinDomain"
        }

        FileReadAccessShare DomainSMBShare
        {
            Name = $WELogFolder
            Path = $WELogPath
            Account = $WEDCComputerAccount,$WEPSComputerAccount
            DependsOn = " [File]ShareFolder"
        }

        OpenFirewallPortForSCCM OpenFirewall
        {
            Name = " DPMP"
            Role = " Distribution Point" ," Management Point"
            DependsOn = " [JoinDomain]JoinDomain"
        }

        AddUserToLocalAdminGroup AddADUserToLocalAdminGroup {
            Name = $($WEAdmincreds.UserName)
            DomainName = $WEDomainName
            DependsOn = " [FileReadAccessShare]DomainSMBShare"
        }

        AddUserToLocalAdminGroup AddADComputerToLocalAdminGroup {
            Name = " $WEPrimarySiteName"
            DomainName = $WEDomainName
            DependsOn = " [FileReadAccessShare]DomainSMBShare"
        }

        WriteConfigurationFile WriteDPMPFinished
        {
            Role = " DPMP"
            LogPath = $WELogPath
            WriteNode = " DPMPFinished"
            Status = " Passed"
            Ensure = " Present"
            DependsOn = " [AddUserToLocalAdminGroup]AddADUserToLocalAdminGroup" ," [AddUserToLocalAdminGroup]AddADComputerToLocalAdminGroup"
        }
    }
}


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
