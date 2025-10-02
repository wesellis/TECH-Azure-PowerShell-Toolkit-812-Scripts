#Requires -Version 7.4
#Requires -Modules xComputerManagement, CDisk, xActiveDirectory, xDisk, xSql, xNetworking

<#
.SYNOPSIS
    Prepare SQL Server for Always On Configuration

.DESCRIPTION
    Azure DSC configuration to prepare SQL Server for Always On Availability Groups.
    Configures clustering, domain join, firewall rules, SQL logins, and storage settings.

.PARAMETER DomainName
    Active Directory domain name

.PARAMETER Admincreds
    Domain administrator credentials

.PARAMETER SQLServicecreds
    SQL Server service account credentials

.PARAMETER DatabaseEnginePort
    Port for database engine (default: 1433)

.PARAMETER DatabaseMirrorPort
    Port for database mirroring (default: 5022)

.PARAMETER ProbePortNumber
    Port for load balancer probe (default: 59999)

.PARAMETER NumberOfDisks
    Number of data disks to configure

.PARAMETER WorkloadType
    Type of SQL workload (OLTP, DW, General)

.PARAMETER DomainNetbiosName
    NetBIOS name of the domain

.PARAMETER RetryCount
    Number of retry attempts (default: 20)

.PARAMETER RetryIntervalSec
    Interval between retries in seconds (default: 30)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate DSC modules and SQL Server
    Must be run on SQL Server nodes
#>

Configuration PrepSQLAO {
    param(
        [Parameter(Mandatory = $true)]
        [String]$DomainName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SQLServicecreds,

        [Parameter(Mandatory = $false)]
        [UInt32]$DatabaseEnginePort = 1433,

        [Parameter(Mandatory = $false)]
        [UInt32]$DatabaseMirrorPort = 5022,

        [Parameter(Mandatory = $false)]
        [UInt32]$ProbePortNumber = 59999,

        [Parameter(Mandatory = $true)]
        [UInt32]$NumberOfDisks,

        [Parameter(Mandatory = $true)]
        [ValidateSet("OLTP", "DW", "General")]
        [String]$WorkloadType,

        [Parameter(Mandatory = $false)]
        [String]$DomainNetbiosName = (Get-NetBIOSName -DomainName $DomainName),

        [Parameter(Mandatory = $false)]
        [Int]$RetryCount = 20,

        [Parameter(Mandatory = $false)]
        [Int]$RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName xComputerManagement, CDisk, xActiveDirectory, xDisk, xSql, xNetworking

    # Create credential objects with proper domain prefixes
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential(
        "${DomainNetbiosName}\$($Admincreds.UserName)",
        $Admincreds.Password
    )

    [System.Management.Automation.PSCredential]$DomainFQDNCreds = New-Object System.Management.Automation.PSCredential(
        "${DomainName}\$($Admincreds.UserName)",
        $Admincreds.Password
    )

    [System.Management.Automation.PSCredential]$SQLCreds = New-Object System.Management.Automation.PSCredential(
        "${DomainNetbiosName}\$($SQLServicecreds.UserName)",
        $SQLServicecreds.Password
    )

    # Configure TLS
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $RebootVirtualMachine = $false
    if ($DomainName) {
        $RebootVirtualMachine = $true
    }

    # Find next available drive letter
    $NewDiskLetter = Get-ChildItem function:[f-z]: -Name | Where-Object { !(Test-Path $_) } | Select-Object -First 1
    $NextAvailableDiskLetter = $NewDiskLetter[0]

    # Wait for SQL setup to complete
    WaitForSqlSetup

    Node localhost {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyOnly'
        }

        # Configure virtual data disk for SQL
        xSqlCreateVirtualDataDisk NewVirtualDisk {
            NumberOfDisks = $NumberOfDisks
            NumberOfColumns = $NumberOfDisks
            DiskLetter = $NextAvailableDiskLetter
            OptimizationType = $WorkloadType
            StartingDeviceID = 2
            RebootVirtualMachine = $RebootVirtualMachine
        }

        # Install failover clustering
        WindowsFeature FC {
            Name = "Failover-Clustering"
            Ensure = "Present"
        }

        WindowsFeature FailoverClusterTools {
            Ensure = "Present"
            Name = "RSAT-Clustering-Mgmt"
            DependsOn = "[WindowsFeature]FC"
        }

        WindowsFeature FCPS {
            Name = "RSAT-Clustering-PowerShell"
            Ensure = "Present"
        }

        WindowsFeature ADPS {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        # Install SQL Server PowerShell module
        Script SqlServerPowerShell {
            SetScript = {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
                Install-PackageProvider -Name NuGet -Force
                Install-Module -Name SqlServer -AllowClobber -Force
                Import-Module -Name SqlServer -ErrorAction SilentlyContinue
            }
            TestScript = {
                Import-Module -Name SqlServer -ErrorAction SilentlyContinue
                if (Get-Module -Name SqlServer) { $true } else { $false }
            }
            GetScript = {
                Import-Module -Name SqlServer -ErrorAction SilentlyContinue
                @{Ensure = if (Get-Module -Name SqlServer) { "Present" } else { "Absent" } }
            }
        }

        # Wait for domain
        xWaitForADDomain DscForestWait {
            DomainName = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[WindowsFeature]ADPS"
        }

        # Join domain
        xComputer DomainJoin {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        # Configure firewall rules
        xFirewall DatabaseEngineFirewallRule {
            Direction = "Inbound"
            Name = "SQL-Server-Database-Engine-TCP-In"
            DisplayName = "SQL Server Database Engine (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for the Database Engine."
            DisplayGroup = "SQL Server"
            State = "Enabled"
            Access = "Allow"
            Protocol = "TCP"
            LocalPort = $DatabaseEnginePort -as [String]
            Ensure = "Present"
            DependsOn = "[xComputer]DomainJoin"
        }

        xFirewall DatabaseMirroringFirewallRule {
            Direction = "Inbound"
            Name = "SQL-Server-Database-Mirroring-TCP-In"
            DisplayName = "SQL Server Database Mirroring (TCP-In)"
            Description = "Inbound rule for SQL Server to allow TCP traffic for Database Mirroring."
            DisplayGroup = "SQL Server"
            State = "Enabled"
            Access = "Allow"
            Protocol = "TCP"
            LocalPort = $DatabaseMirrorPort -as [String]
            Ensure = "Present"
            DependsOn = "[xComputer]DomainJoin"
        }

        xFirewall LoadBalancerProbePortFirewallRule {
            Direction = "Inbound"
            Name = "SQL-Server-Probe-Port-TCP-In"
            DisplayName = "SQL Server Probe Port (TCP-In)"
            Description = "Inbound rule to allow TCP traffic for the Load Balancer Probe Port."
            DisplayGroup = "SQL Server"
            State = "Enabled"
            Access = "Allow"
            Protocol = "TCP"
            LocalPort = $ProbePortNumber -as [String]
            Ensure = "Present"
            DependsOn = "[xComputer]DomainJoin"
        }

        # Configure SQL logins
        xSqlLogin AddDomainAdminAccountToSysadminServerRole {
            Name = $DomainCreds.UserName
            LoginType = "WindowsUser"
            ServerRoles = "sysadmin"
            Enabled = $true
            Credential = $Admincreds
            PsDscRunAsCredential = $Admincreds
            DependsOn = "[xComputer]DomainJoin"
        }

        xADUser CreateSqlServerServiceAccount {
            DomainAdministratorCredential = $DomainCreds
            DomainName = $DomainName
            UserName = $SQLServicecreds.UserName
            Password = $SQLServicecreds
            Ensure = "Present"
            DependsOn = "[xSqlLogin]AddDomainAdminAccountToSysadminServerRole"
        }

        xSqlLogin AddSqlServerServiceAccountToSysadminServerRole {
            Name = $SQLCreds.UserName
            LoginType = "WindowsUser"
            ServerRoles = "sysadmin"
            Enabled = $true
            Credential = $Admincreds
            PsDscRunAsCredential = $Admincreds
            DependsOn = "[xADUser]CreateSqlServerServiceAccount"
        }

        # Configure SQL endpoint
        xSqlTsqlEndpoint AddSqlServerEndpoint {
            InstanceName = "MSSQLSERVER"
            PortNumber = $DatabaseEnginePort
            SqlAdministratorCredential = $Admincreds
            PsDscRunAsCredential = $Admincreds
            DependsOn = "[xSqlLogin]AddSqlServerServiceAccountToSysadminServerRole"
        }

        # Configure storage settings
        xSQLServerStorageSettings AddSQLServerStorageSettings {
            InstanceName = "MSSQLSERVER"
            OptimizationType = $WorkloadType
            DependsOn = "[xSqlTsqlEndpoint]AddSqlServerEndpoint"
        }

        # Configure SQL Server with Always On
        xSqlServer ConfigureSqlServerWithAlwaysOn {
            InstanceName = $env:COMPUTERNAME
            SqlAdministratorCredential = $Admincreds
            ServiceCredential = $SQLCreds
            MaxDegreeOfParallelism = 1
            FilePath = "F:\DATA"
            LogPath = "F:\LOG"
            DomainAdministratorCredential = $DomainFQDNCreds
            EnableTcpIp = $true
            PsDscRunAsCredential = $Admincreds
            DependsOn = "[xSqlLogin]AddSqlServerServiceAccountToSysadminServerRole"
        }
    }
}

function Get-NetBIOSName {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length = $DomainName.IndexOf('.')
        if ($length -ge 16) {
            $length = 15
        }
        return $DomainName.Substring(0, $length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0, 15)
        }
        else {
            return $DomainName
        }
    }
}

function WaitForSqlSetup {
    while ($true) {
        try {
            Get-ScheduledTaskInfo -TaskName "\ConfigureSqlImageTasks\RunConfigureImage" -ErrorAction Stop
            Start-Sleep -Seconds 5
        }
        catch {
            break
        }
    }
}

# Example usage:
# PrepSQLAO -DomainName 'contoso.com' -Admincreds $adminCred -SQLServicecreds $sqlCred -NumberOfDisks 4 -WorkloadType 'OLTP'
# Start-DscConfiguration -Path .\PrepSQLAO -Wait -Verbose -Force