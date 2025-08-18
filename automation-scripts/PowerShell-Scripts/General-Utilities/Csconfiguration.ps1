<#
.SYNOPSIS
    Csconfiguration

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
    We Enhanced Csconfiguration

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
    $WECM = " CMCB"
    $WELogPath = " c:\$WELogFolder"
    $WEDName = $WEDomainName.Split(" ." )[0]
    $WEDCComputerAccount = " $WEDName\$WEDCName$"
    $WEPSComputerAccount = " $WEDName\$WEPSName$"
    $WEDPMPComputerAccount = " $WEDName\$WEDPMPName$"
    [String]$WEClients = [system.String]::Join(" ," , $WEClientName)
   ;  $WECurrentRole = " CS"
   ;  $WEPrimarySiteName = $WEPSName.split(" ." )[0] + " $"
    
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)

    Node LOCALHOST
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

        AddBuiltinPermission AddSQLPermission
        {
            Ensure = " Present"
            DependsOn = " [SetCustomPagingFile]PagingSettings"
        }

        InstallFeatureForSCCM InstallFeature
        {
            NAME = " CS"
            Role = " Site Server"
            DependsOn = " [AddBuiltinPermission]AddSQLPermission"
        }

        InstallADK ADKInstall
        {
            ADKPath = " C:\adksetup.exe"
            ADKWinPEPath = " c:\adksetupwinpe.exe"
            Ensure = " Present"
            DependsOn = " [InstallFeatureForSCCM]InstallFeature"
        }

        DownloadAndInstallODBC DownloadAndInstallODBC
        {
            Ensure = " Present"
            DependsOn = " [InstallADK]ADKInstall"
        }

        DownloadSCCM DownLoadSCCM
        {
            CM = $WECM
            Ensure = " Present"
            DependsOn = " [DownloadAndInstallODBC]DownloadAndInstallODBC"
        }

        SetDNS DnsServerAddress
        {
            DNSIPAddress = $WEDNSIPAddress
            Ensure = " Present"
            DependsOn = " [DownloadSCCM]DownLoadSCCM"
        }

        WaitForDomainReady WaitForDomain
        {
            Ensure = " Present"
            DCName = $WEDCName
            WaitSeconds = 0
            DependsOn = " [SetDNS]DnsServerAddress"
        }

        JoinDomain JoinDomain
        {
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            DependsOn = " [WaitForDomainReady]WaitForDomain"
        }
        
        File ShareFolder
        {            
            DestinationPath = $WELogPath     
            Type = 'Directory'            
            Ensure = 'Present'
            DependsOn = " [JoinDomain]JoinDomain"
        }

        WaitForConfigurationFile WaitPSJoinDomain
        {
            Role = " DC"
            MachineName = $WEDCName
            LogFolder = $WELogFolder
            ReadNode = " PSJoinDomain"
            Ensure = " Present"
            DependsOn = " [File]ShareFolder"
        }

        FileReadAccessShare DomainSMBShare
        {
            Name = $WELogFolder
            Path = $WELogPath
            Account = $WEDCComputerAccount,$WEPSComputerAccount
            DependsOn = " [WaitForConfigurationFile]WaitPSJoinDomain"
        }
        
        OpenFirewallPortForSCCM OpenFirewall
        {
            Name = " CS"
            Role = " Site Server"
            DependsOn = " [JoinDomain]JoinDomain"
        }

        WaitForConfigurationFile DelegateControl
        {
            Role = " DC"
            MachineName = $WEDCName
            LogFolder = $WELogFolder
            ReadNode = " DelegateControl"
            Ensure = " Present"
            DependsOn = " [OpenFirewallPortForSCCM]OpenFirewall"
        }

        ChangeSQLServicesAccount ChangeToLocalSystem
        {
            SQLInstanceName = " MSSQLSERVER"
            Ensure = " Present"
            DependsOn = " [WaitForConfigurationFile]DelegateControl"
        }

        FileReadAccessShare CMSourceSMBShare
        {
            Name = $WECM
            Path = " c:\$WECM"
            Account = $WEDCComputerAccount
            DependsOn = " [ChangeSQLServicesAccount]ChangeToLocalSystem"
        }

        AddUserToLocalAdminGroup AddADComputerToLocalAdminGroup {
            Name = " $WEPrimarySiteName"
            DomainName = $WEDomainName
            DependsOn = " [FileReadAccessShare]CMSourceSMBShare"
        }

        RegisterTaskScheduler InstallAndUpdateSCCM
        {
            TaskName = " ScriptWorkFlow"
            ScriptName = " ScriptWorkFlow.ps1"
            ScriptPath = $WEPSScriptRoot
            ScriptArgument = " $WEDomainName $WECM $WEDName\$($WEAdmincreds.UserName) $WEDPMPName $WEClients $WEConfiguration $WECurrentRole $WELogFolder $WECSName $WEPSName"
            Ensure = " Present"
            DependsOn = " [AddUserToLocalAdminGroup]AddADComputerToLocalAdminGroup"
        }
    }
}


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
