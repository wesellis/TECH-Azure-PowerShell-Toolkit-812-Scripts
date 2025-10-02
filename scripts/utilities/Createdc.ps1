#Requires -Version 7.4
#Requires -Modules xActiveDirectory, xNetworking, xPendingReboot

<#
.SYNOPSIS
    Create Domain Controller

.DESCRIPTION
    Azure DSC configuration for creating a new domain controller.
    This configuration installs and configures Active Directory Domain Services,
    DNS, and related management tools.

.PARAMETER DomainName
    The name of the domain to create or join

.PARAMETER Admincreds
    Administrator credentials for the domain

.PARAMETER RetryCount
    Number of retry attempts for operations (default: 20)

.PARAMETER RetryIntervalSec
    Interval in seconds between retry attempts (default: 30)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
    This is a DSC configuration that must be compiled and applied
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [String]$DomainName,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Admincreds,

    [Parameter(Mandatory = $false)]
    [Int]$RetryCount = 20,

    [Parameter(Mandatory = $false)]
    [Int]$RetryIntervalSec = 30
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Defining CreateDC DSC Configuration..."

    configuration CreateDC {
        param(
            [Parameter(Mandatory = $true)]
            [String]$DomainName,

            [Parameter(Mandatory = $true)]
            [System.Management.Automation.PSCredential]$Admincreds,

            [Parameter(Mandatory = $false)]
            [Int]$RetryCount = 20,

            [Parameter(Mandatory = $false)]
            [Int]$RetryIntervalSec = 30
        )

        Import-DscResource -ModuleName xActiveDirectory
        Import-DscResource -ModuleName xNetworking
        Import-DscResource -ModuleName xPendingReboot

        [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

        Node localhost {
            LocalConfigurationManager {
                ConfigurationMode = 'ApplyOnly'
                RebootNodeIfNeeded = $true
            }

            WindowsFeature DNS {
                Ensure = "Present"
                Name = "DNS"
            }

            WindowsFeature DnsTools {
                Ensure = "Present"
                Name = "RSAT-DNS-Server"
                DependsOn = "[WindowsFeature]DNS"
            }

            xDnsServerAddress DnsServerAddress {
                Address = '127.0.0.1'
                InterfaceAlias = 'Ethernet'
                AddressFamily = 'IPv4'
                DependsOn = "[WindowsFeature]DNS"
            }

            WindowsFeature ADDSInstall {
                Ensure = "Present"
                Name = "AD-Domain-Services"
                DependsOn = "[WindowsFeature]DNS"
            }

            WindowsFeature ADDSTools {
                Ensure = "Present"
                Name = "RSAT-ADDS-Tools"
                DependsOn = "[WindowsFeature]ADDSInstall"
            }

            WindowsFeature ADAdminCenter {
                Ensure = "Present"
                Name = "RSAT-AD-AdminCenter"
                DependsOn = "[WindowsFeature]ADDSTools"
            }

            xADDomain FirstDS {
                DomainName = $DomainName
                DomainAdministratorCredential = $DomainCreds
                SafemodeAdministratorPassword = $DomainCreds
                DatabasePath = "C:\NTDS"
                LogPath = "C:\NTDS"
                SysvolPath = "C:\SYSVOL"
                DependsOn = @("[WindowsFeature]ADDSInstall", "[xDnsServerAddress]DnsServerAddress")
            }

            xWaitForADDomain DscForestWait {
                DomainName = $DomainName
                DomainUserCredential = $DomainCreds
                RetryCount = $RetryCount
                RetryIntervalSec = $RetryIntervalSec
                DependsOn = "[xADDomain]FirstDS"
            }

            xADRecycleBin RecycleBin {
                EnterpriseAdministratorCredential = $DomainCreds
                ForestFQDN = $DomainName
                DependsOn = "[xWaitForADDomain]DscForestWait"
            }

            xPendingReboot RebootAfterPromotion {
                Name = "RebootAfterDCPromotion"
                DependsOn = "[xADDomain]FirstDS"
            }
        }
    }

    Write-Output "CreateDC DSC Configuration defined successfully"
    Write-Output "To use this configuration, call: CreateDC -DomainName 'YourDomain' -Admincreds \$YourCredentials"
    Write-Output "Domain Name: $DomainName"
    Write-Output "Retry Count: $RetryCount"
    Write-Output "Retry Interval: $RetryIntervalSec seconds"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}