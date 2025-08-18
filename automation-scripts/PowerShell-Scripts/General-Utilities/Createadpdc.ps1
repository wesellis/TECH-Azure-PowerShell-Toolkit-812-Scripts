<#
.SYNOPSIS
    Createadpdc

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
    We Enhanced Createadpdc

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿configuration CreateADPDC 
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
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Int]$WERetryCount = 20,
        [Int]$WERetryIntervalSec = 30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)
   ;  $WEInterface = Get-NetAdapter | Where Name -Like " Ethernet*" | Select-Object -First 1
   ;  $WEInterfaceAlias = $($WEInterface.Name)

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DNS { 
            Ensure = " Present" 
            Name   = " DNS"		
        }

        Script GuestAgent
        {
            SetScript  = {
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value DNS
                Write-Verbose -Verbose " GuestAgent depends on DNS"
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = " [WindowsFeature]DNS"
        }
        
        Script EnableDNSDiags {
            SetScript  = { 
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose " Enabling DNS client diagnostics" 
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = " [WindowsFeature]DNS"
        }

        WindowsFeature DnsTools {
            Ensure    = " Present"
            Name      = " RSAT-DNS-Server"
            DependsOn = " [WindowsFeature]DNS"
        }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $WEInterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = " [WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$WERetryIntervalSec
            RetryCount = $WERetryCount
        }

        xDisk ADDataDisk {
            DiskNumber  = 2
            DriveLetter = " F"
            DependsOn   = " [xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall { 
            Ensure    = " Present" 
            Name      = " AD-Domain-Services"
            DependsOn = " [WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools {
            Ensure    = " Present"
            Name      = " RSAT-ADDS-Tools"
            DependsOn = " [WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter {
            Ensure    = " Present"
            Name      = " RSAT-AD-AdminCenter"
            DependsOn = " [WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName                    = $WEDomainName
            DomainAdministratorCredential = $WEDomainCreds
            SafemodeAdministratorPassword = $WEDomainCreds
            DatabasePath                  = " F:\NTDS"
            LogPath                       = " F:\NTDS"
            SysvolPath                    = " F:\SYSVOL"
            DependsOn                     = @(" [xDisk]ADDataDisk" , " [WindowsFeature]ADDSInstall" )
        } 

    }
} 



} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
