<#
.SYNOPSIS
    We Enhanced Prepareadbdc

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

configuration PrepareADBDC
{
   [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [String]$WEDNSServer,

        [Int]$WERetryCount=20,
        [Int]$WERetryIntervalSec=30
    )

    Import-DscResource -ModuleName  xStorage, xNetworking
    $WEInterface=Get-NetAdapter|Where Name -Like "Ethernet*" |Select-Object -First 1
   ;  $WEInterfaceAlias=$($WEInterface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        xWaitforDisk Disk2
        {
                DiskNumber = 2
                RetryIntervalSec =$WERetryIntervalSec
                RetryCount = $WERetryCount
        }

        xDisk ADDataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
            DependsOn = " [xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall
        {
            Ensure = " Present"
            Name = " AD-Domain-Services"
        }

        WindowsFeature ADDSTools
        {
            Ensure = " Present"
            Name = " RSAT-ADDS-Tools"
            DependsOn = " [WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = " Present"
            Name = " RSAT-AD-AdminCenter"
            DependsOn = " [WindowsFeature]ADDSTools"
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = $WEDNSServer
            InterfaceAlias = $WEInterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn=" [WindowsFeature]ADDSInstall"
        }
   }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
