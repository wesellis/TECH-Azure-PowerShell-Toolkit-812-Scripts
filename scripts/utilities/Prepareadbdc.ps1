#Requires -Version 7.4
#Requires -Modules xStorage, xNetworking

<#
.SYNOPSIS
    Prepare AD Backup Domain Controller

.DESCRIPTION
    Azure DSC configuration to prepare a server as an Active Directory
    backup domain controller. Configures disks, installs AD DS features,
    and sets DNS server address.

.PARAMETER DNSServer
    IP address of the primary DNS server

.PARAMETER RetryCount
    Number of retry attempts for disk operations (default: 20)

.PARAMETER RetryIntervalSec
    Interval in seconds between retry attempts (default: 30)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and DSC modules
    Designed for Azure VM domain controller preparation
#>

Configuration PrepareADBDC {
    param(
        [Parameter(Mandatory = $true)]
        [String]$DNSServer,

        [Parameter(Mandatory = $false)]
        [Int]$RetryCount = 20,

        [Parameter(Mandatory = $false)]
        [Int]$RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName xStorage, xNetworking

    # Get the primary network interface
    $Interface = Get-NetAdapter | Where-Object { $_.Name -Like "Ethernet*" } | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node localhost {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyOnly'
        }

        # Wait for data disk to be available
        xWaitforDisk Disk2 {
            DiskNumber = 2
            RetryIntervalSec = $RetryIntervalSec
            RetryCount = $RetryCount
        }

        # Format and mount data disk
        xDisk ADDataDisk {
            DiskNumber = 2
            DriveLetter = "F"
            FSLabel = "AD Data"
            DependsOn = "[xWaitForDisk]Disk2"
        }

        # Install AD Domain Services
        WindowsFeature ADDSInstall {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            IncludeAllSubFeature = $true
        }

        # Install AD DS management tools
        WindowsFeature ADDSTools {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        # Install AD Admin Center
        WindowsFeature ADAdminCenter {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSTools"
        }

        # Install DNS management tools
        WindowsFeature DNSTools {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        # Configure DNS server address
        xDnsServerAddress DnsServerAddress {
            Address = $DNSServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily = 'IPv4'
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
    }
}

# Example usage:
# PrepareADBDC -DNSServer '10.0.0.4'
# Start-DscConfiguration -Path .\PrepareADBDC -Wait -Verbose -Force