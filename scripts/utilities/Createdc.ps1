#Requires -Version 7.0

<#`n.SYNOPSIS
    Createdc

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
configuration CreateDC
{
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,
        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    )
    Import-DscResource -ModuleName xActiveDirectory, xNetworking
    [System.Management.Automation.PSCredential] $DomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" ${DomainName}\$($Admincreds.UserName)" , $Admincreds.Password)
$Interface = Get-NetAdapter -ErrorAction Stop | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
$InterfaceAlias = $($Interface.Name)
    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }
        WindowsFeature DNS {
            Ensure = "Present"
            Name   = "DNS"
        }
        Script EnableDNSDiags {
            SetScript  = {
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics"
            }
            GetScript  = { @{} }
            TestScript = { $false }
            DependsOn  = " [WindowsFeature]DNS"
        }
        WindowsFeature DnsTools {
            Ensure    = "Present"
            Name      = "RSAT-DNS-Server"
            DependsOn = " [WindowsFeature]DNS"
        }
        xDnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = " [WindowsFeature]DNS"
        }
        WindowsFeature ADDSInstall {
            Ensure    = "Present"
            Name      = "AD-Domain-Services"
            DependsOn = " [WindowsFeature]DNS"
        }
        WindowsFeature ADDSTools {
            Ensure    = "Present"
            Name      = "RSAT-ADDS-Tools"
            DependsOn = " [WindowsFeature]ADDSInstall"
        }
        WindowsFeature ADAdminCenter {
            Ensure    = "Present"
            Name      = "RSAT-AD-AdminCenter"
            DependsOn = " [WindowsFeature]ADDSInstall"
        }
        xADDomain FirstDS
        {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DependsOn                     = @(" [WindowsFeature]ADDSInstall" )
        }
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
