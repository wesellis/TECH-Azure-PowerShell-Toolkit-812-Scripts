#Requires -Version 7.4

<#
.SYNOPSIS
    Create AD PDC

.DESCRIPTION
    Azure automation script containing a PowerShell DSC configuration to create an Active Directory Primary Domain Controller.
    This configuration sets up DNS, Active Directory Domain Services, and configures the necessary dependencies.

.PARAMETER DomainName
    The name of the Active Directory domain to create

.PARAMETER AdminCreds
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
    Requires xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot DSC modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [Parameter(Mandatory=$true)]
    [System.Management.Automation.PSCredential]$AdminCreds,

    [Parameter(Mandatory=$false)]
    [int]$RetryCount = 20,

    [Parameter(Mandatory=$false)]
    [int]$RetryIntervalSec = 30
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Defining CreateADPDC DSC Configuration..."

    # DSC Configuration for Active Directory Primary Domain Controller
    configuration CreateADPDC {
        param(
            [Parameter(Mandatory=$true)]
            [string]$DomainName,

            [Parameter(Mandatory=$true)]
            [System.Management.Automation.PSCredential]$AdminCreds,

            [Parameter(Mandatory=$false)]
            [int]$RetryCount = 20,

            [Parameter(Mandatory=$false)]
            [int]$RetryIntervalSec = 30
        )

        # Import required DSC resources
        Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot

        # Create domain credentials
        [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential(
            "${DomainName}\$($AdminCreds.UserName)",
            $AdminCreds.Password
        )

        # Get network interface
        $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
        $InterfaceAlias = $Interface.Name

        Node localhost {
            # Configure Local Configuration Manager
            LocalConfigurationManager {
                RebootNodeIfNeeded = $true
            }

            # Install DNS Server feature
            WindowsFeature DNS {
                Ensure = "Present"
                Name   = "DNS"
            }

            # Configure Guest Agent dependency
            Script GuestAgent {
                SetScript  = {
                    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name DependOnService -Type MultiString -Value DNS
                    Write-Verbose -Verbose "GuestAgent depends on DNS"
                }
                GetScript  = { @{} }
                TestScript = { $false }
                DependsOn  = "[WindowsFeature]DNS"
            }

            # Enable DNS diagnostics
            Script EnableDNSDiags {
                SetScript  = {
                    Set-DnsServerDiagnostics -All $true
                    Write-Verbose -Verbose "Enabling DNS client diagnostics"
                }
                GetScript  = { @{} }
                TestScript = { $false }
                DependsOn  = "[WindowsFeature]DNS"
            }

            # Install DNS management tools
            WindowsFeature DnsTools {
                Ensure    = "Present"
                Name      = "RSAT-DNS-Server"
                DependsOn = "[WindowsFeature]DNS"
            }

            # Configure DNS server address
            xDnsServerAddress DnsServerAddress {
                Address        = '127.0.0.1'
                InterfaceAlias = $InterfaceAlias
                AddressFamily  = 'IPv4'
                DependsOn      = "[WindowsFeature]DNS"
            }

            # Wait for additional disk
            xWaitforDisk Disk2 {
                DiskNumber       = 2
                RetryIntervalSec = $RetryIntervalSec
                RetryCount       = $RetryCount
            }

            # Configure additional disk for AD data
            xDisk ADDataDisk {
                DiskNumber  = 2
                DriveLetter = "F"
                DependsOn   = "[xWaitForDisk]Disk2"
            }

            # Install Active Directory Domain Services
            WindowsFeature ADDSInstall {
                Ensure    = "Present"
                Name      = "AD-Domain-Services"
                DependsOn = "[WindowsFeature]DNS"
            }

            # Install AD management tools
            WindowsFeature ADDSTools {
                Ensure    = "Present"
                Name      = "RSAT-ADDS-Tools"
                DependsOn = "[WindowsFeature]ADDSInstall"
            }

            # Install AD Admin Center
            WindowsFeature ADAdminCenter {
                Ensure    = "Present"
                Name      = "RSAT-AD-AdminCenter"
                DependsOn = "[WindowsFeature]ADDSInstall"
            }

            # Create the Active Directory domain
            xADDomain FirstDS {
                DomainName                    = $DomainName
                DomainAdministratorCredential = $DomainCreds
                SafemodeAdministratorPassword = $DomainCreds
                DatabasePath                  = "F:\NTDS"
                LogPath                       = "F:\NTDS"
                SysvolPath                    = "F:\SYSVOL"
                DependsOn                     = @("[xDisk]ADDataDisk", "[WindowsFeature]ADDSInstall")
            }
        }
    }

    Write-Output "CreateADPDC DSC Configuration defined successfully"
    Write-Output "To use this configuration, call: CreateADPDC -DomainName 'YourDomain' -AdminCreds \$YourCredentials"
    Write-Output "Domain Name: $DomainName"
    Write-Output "Retry Count: $RetryCount"
    Write-Output "Retry Interval: $RetryIntervalSec seconds"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}