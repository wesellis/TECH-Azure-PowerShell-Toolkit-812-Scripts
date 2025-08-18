<#
.SYNOPSIS
    Prepsqlao

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
    We Enhanced Prepsqlao

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


configuration PrepSQLAO
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [String]$WEDomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WESQLServicecreds,

        [UInt32]$WEDatabaseEnginePort = 1433,
        
        [UInt32]$WEDatabaseMirrorPort = 5022,

        [UInt32]$WEProbePortNumber = 59999,

        [Parameter(Mandatory)]
        [UInt32]$WENumberOfDisks,

        [Parameter(Mandatory)]
        [String]$WEWorkloadType,

        [String]$WEDomainNetbiosName=(Get-NetBIOSName -DomainName $WEDomainName),

        [Int]$WERetryCount=20,
        [Int]$WERetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement,CDisk,xActiveDirectory,XDisk,xSql,xNetworking
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainNetbiosName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)
    [System.Management.Automation.PSCredential]$WEDomainFQDNCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)
    [System.Management.Automation.PSCredential]$WESQLCreds = New-Object System.Management.Automation.PSCredential (" ${DomainNetbiosName}\$($WESQLServicecreds.UserName)" , $WESQLServicecreds.Password)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $WERebootVirtualMachine = $false

    if ($WEDomainName)
    {
        $WERebootVirtualMachine = $true
    }

    #Finding the next avaiable disk letter for Add disk
   ;  $WENewDiskLetter = ls function:[f-z]: -n | ?{ !(test-path $_) } | select -First 1 

   ;  $WENextAvailableDiskLetter = $WENewDiskLetter[0]
    
    WaitForSqlSetup

    Node localhost
    {
        xSqlCreateVirtualDataDisk NewVirtualDisk
        {
            NumberOfDisks = $WENumberOfDisks
            NumberOfColumns = $WENumberOfDisks
            DiskLetter = $WENextAvailableDiskLetter
            OptimizationType = $WEWorkloadType
            StartingDeviceID = 2
            RebootVirtualMachine = $WERebootVirtualMachine
        }

        WindowsFeature FC
        {
            Name = " Failover-Clustering"
            Ensure = " Present"
        }

        WindowsFeature FailoverClusterTools 
        { 
            Ensure = " Present" 
            Name = " RSAT-Clustering-Mgmt"
            DependsOn = " [WindowsFeature]FC"
        } 

        WindowsFeature FCPS
        {
            Name = " RSAT-Clustering-PowerShell"
            Ensure = " Present"
        }

        WindowsFeature ADPS
        {
            Name = " RSAT-AD-PowerShell"
            Ensure = " Present"
        }

        Script SqlServerPowerShell
        {
            SetScript = '[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Install-PackageProvider -Name NuGet -Force; Install-Module -Name SqlServer -AllowClobber -Force; Import-Module -Name SqlServer -ErrorAction SilentlyContinue'
            TestScript = 'Import-Module -Name SqlServer -ErrorAction SilentlyContinue; if (Get-Module -Name SqlServer) { $WETrue } else { $WEFalse }'
            GetScript = 'Import-Module -Name SqlServer -ErrorAction SilentlyContinue; @{Ensure = if (Get-Module -Name SqlServer) {" Present" } else {" Absent" }}'
        }

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $WEDomainName 
            DomainUserCredential= $WEDomainCreds
            RetryCount = $WERetryCount 
            RetryIntervalSec = $WERetryIntervalSec 
	        DependsOn = " [WindowsFeature]ADPS"
        }
        
        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
	        DependsOn = " [xWaitForADDomain]DscForestWait"
        }

        xFirewall DatabaseEngineFirewallRule
        {
            Direction = " Inbound"
            Name = " SQL-Server-Database-Engine-TCP-In"
            DisplayName = " SQL Server Database Engine (TCP-In)"
            Description = " Inbound rule for SQL Server to allow TCP traffic for the Database Engine."
            DisplayGroup = " SQL Server"
            State = " Enabled"
            Access = " Allow"
            Protocol = " TCP"
            LocalPort = $WEDatabaseEnginePort -as [String]
            Ensure = " Present"
            DependsOn = " [xComputer]DomainJoin"
        }

        xFirewall DatabaseMirroringFirewallRule
        {
            Direction = " Inbound"
            Name = " SQL-Server-Database-Mirroring-TCP-In"
            DisplayName = " SQL Server Database Mirroring (TCP-In)"
            Description = " Inbound rule for SQL Server to allow TCP traffic for the Database Mirroring."
            DisplayGroup = " SQL Server"
            State = " Enabled"
            Access = " Allow"
            Protocol = " TCP"
            LocalPort = $WEDatabaseMirrorPort -as [String]
            Ensure = " Present"
            DependsOn = " [xComputer]DomainJoin"
        }

        xFirewall LoadBalancerProbePortFirewallRule
        {
            Direction = " Inbound"
            Name = " SQL-Server-Probe-Port-TCP-In"
            DisplayName = " SQL Server Probe Port (TCP-In)"
            Description = " Inbound rule to allow TCP traffic for the Load Balancer Probe Port."
            DisplayGroup = " SQL Server"
            State = " Enabled"
            Access = " Allow"
            Protocol = " TCP"
            LocalPort = $WEProbePortNumber -as [String]
            Ensure = " Present"
            DependsOn = " [xComputer]DomainJoin"
        }

        xSqlLogin AddDomainAdminAccountToSysadminServerRole
        {
            Name = $WEDomainCreds.UserName
            LoginType = " WindowsUser"
            ServerRoles = " sysadmin"
            Enabled = $true
            Credential = $WEAdmincreds
            PsDscRunAsCredential = $WEAdmincreds
            DependsOn = " [xComputer]DomainJoin"
        }

        xADUser CreateSqlServerServiceAccount
        {
            DomainAdministratorCredential = $WEDomainCreds
            DomainName = $WEDomainName
            UserName = $WESQLServicecreds.UserName
            Password = $WESQLServicecreds
            Ensure = " Present"
            DependsOn = " [xSqlLogin]AddDomainAdminAccountToSysadminServerRole"
        }

        xSqlLogin AddSqlServerServiceAccountToSysadminServerRole
        {
            Name = $WESQLCreds.UserName
            LoginType = " WindowsUser"
            ServerRoles = " sysadmin"
            Enabled = $true
            Credential = $WEAdmincreds
            PsDscRunAsCredential = $WEAdmincreds
            DependsOn = " [xADUser]CreateSqlServerServiceAccount"
        }
        
        xSqlTsqlEndpoint AddSqlServerEndpoint
        {
            InstanceName = " MSSQLSERVER"
            PortNumber = $WEDatabaseEnginePort
            SqlAdministratorCredential = $WEAdmincreds
            PsDscRunAsCredential = $WEAdmincreds
            DependsOn = " [xSqlLogin]AddSqlServerServiceAccountToSysadminServerRole"
        }

        xSQLServerStorageSettings AddSQLServerStorageSettings
        {
            InstanceName = " MSSQLSERVER"
            OptimizationType = $WEWorkloadType
            DependsOn = " [xSqlTsqlEndpoint]AddSqlServerEndpoint"
        }

        xSqlServer ConfigureSqlServerWithAlwaysOn
        {
            InstanceName = $env:COMPUTERNAME
            SqlAdministratorCredential = $WEAdmincreds
            ServiceCredential = $WESQLCreds
            MaxDegreeOfParallelism = 1
            FilePath = " F:\DATA"
            LogPath = " F:\LOG"
            DomainAdministratorCredential = $WEDomainFQDNCreds
            EnableTcpIp = $true
            PsDscRunAsCredential = $WEAdmincreds
            DependsOn = " [xSqlLogin]AddSqlServerServiceAccountToSysadminServerRole"
        }

        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

    }
}
function WE-Get-NetBIOSName
{ 
    [OutputType([string])]
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [string]$WEDomainName
    )

    if ($WEDomainName.Contains('.')) {
       ;  $length=$WEDomainName.IndexOf('.')
        if ( $length -ge 16) {
           ;  $length=15
        }
        return $WEDomainName.Substring(0,$length)
    }
    else {
        if ($WEDomainName.Length -gt 15) {
            return $WEDomainName.Substring(0,15)
        }
        else {
            return $WEDomainName
        }
    }
}
function WE-WaitForSqlSetup
{
    # Wait for SQL Server Setup to finish before proceeding.
    while ($true)
    {
        try
        {
            Get-ScheduledTaskInfo " \ConfigureSqlImageTasks\RunConfigureImage" -ErrorAction Stop
            Start-Sleep -Seconds 5
        }
        catch
        {
            break
        }
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================