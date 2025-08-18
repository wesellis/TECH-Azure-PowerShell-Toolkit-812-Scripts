<#
.SYNOPSIS
    Dcconfiguration

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
    We Enhanced Dcconfiguration

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
    $WECM = " CMCB"
    $WEDName = $WEDomainName.Split(" ." )[0]
    if($WEConfiguration -ne " Standalone" )
    {
        $WECSComputerAccount = " $WEDName\$WECSName$"
    }
    $WEPSComputerAccount = " $WEDName\$WEPSName$"
    $WEDPMPComputerAccount = " $WEDName\$WEDPMPName$"
   ;  $WEClients = [system.String]::Join(" ," , $WEClientName)
   ;  $WEClientComputerAccount = " $WEDName\$WEClients$"

    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)

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

        InstallFeatureForSCCM InstallFeature
        {
            Name = 'DC'
            Role = 'DC'
            DependsOn = " [SetCustomPagingFile]PagingSettings"
        }
        
        SetupDomain FirstDS
        {
            DomainFullName = $WEDomainName
            SafemodeAdministratorPassword = $WEDomainCreds
            DependsOn = " [InstallFeatureForSCCM]InstallFeature"
        }

        InstallCA InstallCA
        {
            HashAlgorithm = " SHA256"
            DependsOn = " [SetupDomain]FirstDS"
        }

        VerifyComputerJoinDomain WaitForPS
        {
            ComputerName = $WEPSName
            Ensure = " Present"
            DependsOn = " [InstallCA]InstallCA"
        }

        VerifyComputerJoinDomain WaitForDPMP
        {
            ComputerName = $WEDPMPName
            Ensure = " Present"
            DependsOn = " [InstallCA]InstallCA"
        }

        VerifyComputerJoinDomain WaitForClient
        {
            ComputerName = $WEClients
            Ensure = " Present"
            DependsOn = " [InstallCA]InstallCA"
        }

        if ($WEConfiguration -eq 'Standalone') {
            File ShareFolder
            {            
                DestinationPath = $WELogPath     
                Type = 'Directory'            
                Ensure = 'Present'
                DependsOn = @(" [VerifyComputerJoinDomain]WaitForPS" ," [VerifyComputerJoinDomain]WaitForDPMP" ," [VerifyComputerJoinDomain]WaitForClient" )
            }

            FileReadAccessShare DomainSMBShare
            {
                Name = $WELogFolder
                Path = $WELogPath
                Account = $WEPSComputerAccount,$WEDPMPComputerAccount,$WEClientComputerAccount
                DependsOn = " [File]ShareFolder"
            }

            WriteConfigurationFile WriteDelegateControlfinished
            {
                Role = " DC"
                LogPath = $WELogPath
                WriteNode = " DelegateControl"
                Status = " Passed"
                Ensure = " Present"
                DependsOn = @(" [DelegateControl]AddPS" ," [DelegateControl]AddDPMP" )
            }

            WaitForExtendSchemaFile WaitForExtendSchemaFile
            {
                MachineName = $WEPSName
                ExtFolder = $WECM
                Ensure = " Present"
                DependsOn = " [WriteConfigurationFile]WriteDelegateControlfinished"
            }
        }
        else {
            VerifyComputerJoinDomain WaitForCS
            {
                ComputerName = $WECSName
                Ensure = " Present"
                DependsOn = " [InstallCA]InstallCA"
            }

            File ShareFolder
            {            
                DestinationPath = $WELogPath     
                Type = 'Directory'            
                Ensure = 'Present'
                DependsOn = @(" [VerifyComputerJoinDomain]WaitForCS" ," [VerifyComputerJoinDomain]WaitForPS" ," [VerifyComputerJoinDomain]WaitForDPMP" ," [VerifyComputerJoinDomain]WaitForClient" )
            }

            FileReadAccessShare DomainSMBShare
            {
                Name = $WELogFolder
                Path = $WELogPath
                Account = $WECSComputerAccount,$WEPSComputerAccount,$WEDPMPComputerAccount,$WEClientComputerAccount
                DependsOn = " [File]ShareFolder"
            }
            
            WriteConfigurationFile WriteCSJoinDomain
            {
                Role = " DC"
                LogPath = $WELogPath
                WriteNode = " CSJoinDomain"
                Status = " Passed"
                Ensure = " Present"
                DependsOn = " [FileReadAccessShare]DomainSMBShare"
            }

            DelegateControl AddCS
            {
                Machine = $WECSName
                DomainFullName = $WEDomainName
                Ensure = " Present"
                DependsOn = " [WriteConfigurationFile]WriteCSJoinDomain"
            }

            WriteConfigurationFile WriteDelegateControlfinished
            {
                Role = " DC"
                LogPath = $WELogPath
                WriteNode = " DelegateControl"
                Status = " Passed"
                Ensure = " Present"
                DependsOn = @(" [DelegateControl]AddCS" ," [DelegateControl]AddPS" ," [DelegateControl]AddDPMP" )
            }

            WaitForExtendSchemaFile WaitForExtendSchemaFile
            {
                MachineName = $WECSName
                ExtFolder = $WECM
                Ensure = " Present"
                DependsOn = " [WriteConfigurationFile]WriteDelegateControlfinished"
            }
        }

        WriteConfigurationFile WritePSJoinDomain
        {
            Role = " DC"
            LogPath = $WELogPath
            WriteNode = " PSJoinDomain"
            Status = " Passed"
            Ensure = " Present"
            DependsOn = " [FileReadAccessShare]DomainSMBShare"
        }

        WriteConfigurationFile WriteDPMPJoinDomain
        {
            Role = " DC"
            LogPath = $WELogPath
            WriteNode = " DPMPJoinDomain"
            Status = " Passed"
            Ensure = " Present"
            DependsOn = " [FileReadAccessShare]DomainSMBShare"
        }

        WriteConfigurationFile WriteClientJoinDomain
        {
            Role = " DC"
            LogPath = $WELogPath
            WriteNode = " ClientJoinDomain"
            Status = " Passed"
            Ensure = " Present"
            DependsOn = " [FileReadAccessShare]DomainSMBShare"
        }

        DelegateControl AddPS
        {
            Machine = $WEPSName
            DomainFullName = $WEDomainName
            Ensure = " Present"
            DependsOn = " [WriteConfigurationFile]WritePSJoinDomain"
        }

        DelegateControl AddDPMP
        {
            Machine = $WEDPMPName
            DomainFullName = $WEDomainName
            Ensure = " Present"
            DependsOn = " [WriteConfigurationFile]WriteDPMPJoinDomain"
        }
    }
}


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
