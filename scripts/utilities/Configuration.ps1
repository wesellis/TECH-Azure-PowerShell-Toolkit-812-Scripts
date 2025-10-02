#Requires -Version 7.4
#Requires -Modules xActiveDirectory, xComputerManagement, xNetworking

<#
.SYNOPSIS
    DSC Configuration for Domain Join and Gateway

.DESCRIPTION
    Azure DSC configurations for domain joining and RDS gateway setup

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

configuration DomainJoin
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$DomainName,

        [Parameter(Mandatory = $true)]
        [PSCredential]$AdminCreds,

        [Int]$RetryCount = 200,
        [Int]$RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xNetworking

    $DomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ("$DomainName\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADPowershell
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[WindowsFeature]ADPowershell"
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        Registry RdmsEnableUILog
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableUILog"
            ValueType = "Dword"
            ValueData = "1"
        }

        Registry EnableDeploymentUILog
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableDeploymentUILog"
            ValueType = "Dword"
            ValueData = "1"
        }

        Registry EnableTraceLog
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableTraceLog"
            ValueType = "Dword"
            ValueData = "1"
        }

        Registry EnableTraceToFile
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableTraceToFile"
            ValueType = "Dword"
            ValueData = "1"
        }
    }
}

configuration Gateway
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$DomainName,

        [Parameter(Mandatory = $true)]
        [PSCredential]$AdminCreds
    )

    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xNetworking

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature RDS-Gateway
        {
            Ensure = "Present"
            Name = "RDS-Gateway"
        }

        WindowsFeature RDS-Web-Access
        {
            Ensure = "Present"
            Name = "RDS-Web-Access"
        }

        WindowsFeature RSAT-RDS-Tools
        {
            Ensure = "Present"
            Name = "RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }
    }
}

configuration SessionHost
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$DomainName,

        [Parameter(Mandatory = $true)]
        [PSCredential]$AdminCreds
    )

    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xNetworking

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature RDS-RD-Server
        {
            Ensure = "Present"
            Name = "RDS-RD-Server"
        }

        WindowsFeature Desktop-Experience
        {
            Ensure = "Present"
            Name = "Desktop-Experience"
        }

        WindowsFeature RSAT-RDS-Tools
        {
            Ensure = "Present"
            Name = "RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }
    }
}