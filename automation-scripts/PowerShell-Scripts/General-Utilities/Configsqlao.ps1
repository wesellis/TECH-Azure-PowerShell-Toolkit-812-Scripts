<#
.SYNOPSIS
    We Enhanced Configsqlao

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

configuration ConfigSQLAO
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [String]$WEDomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WESQLServiceCreds,

        [Parameter(Mandatory)]
        [String]$WEClusterName,

        [Parameter(Mandatory)]
        [String]$vmNamePrefix,

        [Parameter(Mandatory)]
        [Int]$vmCount,

        [Parameter(Mandatory)]
        [String]$WESqlAlwaysOnAvailabilityGroupName,

        [Parameter(Mandatory)]
        [String]$WESqlAlwaysOnAvailabilityGroupListenerName,

        [Parameter(Mandatory)]
        [String[]]$WEClusterIpAddresses,

        [Parameter(Mandatory)]
        [String]$WEAGListenerIpAddress,

        [Parameter(Mandatory)]
        [String]$WESqlAlwaysOnEndpointName,

        [Parameter(Mandatory)]
        [String]$witnessStorageName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$witnessStorageKey,

        [UInt32]$WEDatabaseEnginePort = 1433,

        [UInt32]$WEDatabaseMirrorPort = 5022,

        [UInt32]$WEProbePortNumber = 59999,

        [String]$WEDomainNetbiosName=(Get-NetBIOSName -DomainName $WEDomainName),

        [Parameter(Mandatory)]
        [UInt32]$WENumberOfDisks,

        [Parameter(Mandatory)]
        [String]$WEWorkloadType,

        [Int]$WERetryCount=20,
        [Int]$WERetryIntervalSec=30

    )

    Import-DscResource -ModuleName xComputerManagement, xFailOverCluster,CDisk,xActiveDirectory,xDisk,xNetworking,xSql
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)
    [System.Management.Automation.PSCredential]$WEDomainFQDNCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)
    [System.Management.Automation.PSCredential]$WESQLCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($WESQLServiceCreds.UserName)" , $WESQLServiceCreds.Password)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12    

    Enable-CredSSPNTLM -DomainName $WEDomainName
    
    $WERebootVirtualMachine = $false

    if ($WEDomainName)
    {
        $WERebootVirtualMachine = $true
    }

    #Finding the next avaiable disk letter for Add disk
    $WENewDiskLetter = ls function:[f-z]: -n | ?{ !(test-path $_) } | select -First 1 
   ;  $WENextAvailableDiskLetter = $WENewDiskLetter[0]

    [System.Collections.ArrayList]$WENodes=@()
    For ($count=0; $count -lt $vmCount; $count++) {
        $WENodes.Add($vmNamePrefix + $WECount.ToString())
    }

    $WEPrimaryReplica = $WENodes[0]
    
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
            Name = "Failover-Clustering"
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
            DependsOn = " [WindowsFeature]FC"
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
            GetScript = 'Import-Module -Name SqlServer -ErrorAction SilentlyContinue; @{Ensure = if (Get-Module -Name SqlServer) {" Present"} else {" Absent"}}'
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

        xCluster FailoverCluster
        {
            Name = $WEClusterName
            DomainAdministratorCredential = $WEDomainCreds
            PsDscRunAsCredential = $WEDomainCreds
            Nodes = $WENodes
            ClusterIPAddresses = $WEClusterIpAddresses
            DependsOn = @(" [WindowsFeature]FCPS"," [xComputer]DomainJoin")
        }

        Script CloudWitness
        {
            SetScript = " Set-ClusterQuorum -CloudWitness -AccountName ${witnessStorageName} -AccessKey $($witnessStorageKey.GetNetworkCredential().Password)"
            TestScript = " (Get-ClusterQuorum).QuorumResource.Name -eq 'Cloud Witness'"
            GetScript = " @{Ensure = if ((Get-ClusterQuorum).QuorumResource.Name -eq 'Cloud Witness') {'Present'} else {'Absent'}}"
            DependsOn = " [xCluster]FailoverCluster"
        }

        xSqlServer ConfigureSqlServerWithAlwaysOn
        {
            InstanceName = $env:COMPUTERNAME
            SqlAdministratorCredential = $WEAdmincreds
            ServiceCredential = $WESQLCreds
            Hadr = " Enabled"
            MaxDegreeOfParallelism = 1
            FilePath = " F:\DATA"
            LogPath = " F:\LOG"
            DomainAdministratorCredential = $WEDomainFQDNCreds
            EnableTcpIp = $true
            PsDscRunAsCredential = $WEAdmincreds
            DependsOn = " [xCluster]FailoverCluster"
        }

        xSqlEndpoint SqlAlwaysOnEndpoint
        {
            InstanceName = $env:COMPUTERNAME
            Name = $WESqlAlwaysOnEndpointName
            PortNumber = $WEDatabaseMirrorPort
            AllowedUser = $WESQLServiceCreds.UserName
            SqlAdministratorCredential = $WESQLCreds
            PsDscRunAsCredential = $WEDomainCreds
            DependsOn = " [xSqlServer]ConfigureSqlServerWithAlwaysOn"
        }

        foreach ($WENode in $WENodes) {
            
            If ($WENode -ne $WEPrimaryReplica) {

                xSqlServer " ConfigSecondaryWithAlwaysOn_$WENode"
                {
                    InstanceName = $WENode
                    SqlAdministratorCredential = $WEAdmincreds
                    Hadr = " Enabled"
                    DomainAdministratorCredential = $WEDomainFQDNCreds
                    PsDscRunAsCredential = $WEDomainCreds
                    DependsOn = " [xCluster]FailoverCluster"
                }

                xSqlEndpoint " SqlSecondaryAlwaysOnEndpoint_$WENode"
                {
                    InstanceName = $WENode
                    Name = $WESqlAlwaysOnEndpointName
                    PortNumber = $WEDatabaseMirrorPort
                    AllowedUser = $WESQLServiceCreds.UserName
                    SqlAdministratorCredential = $WESQLCreds
                    PsDscRunAsCredential = $WEDomainCreds
                    DependsOn=" [xSqlServer]ConfigSecondaryWithAlwaysOn_$WENode"
                }

            }
        
        }

        xSqlAvailabilityGroup SqlAG
        {
            Name = $WESqlAlwaysOnAvailabilityGroupName
            ClusterName = $WEClusterName
            InstanceName = $env:COMPUTERNAME
            PortNumber = $WEDatabaseMirrorPort
            DomainCredential =$WEDomainCreds
            SqlAdministratorCredential = $WEAdmincreds
            PsDscRunAsCredential = $WEDomainCreds
	        DependsOn=" [xSqlEndpoint]SqlSecondaryAlwaysOnEndpoint_$($WENodes[-1])"
        }
           
        xSqlAvailabilityGroupListener SqlAGListener
        {
            Name = $WESqlAlwaysOnAvailabilityGroupListenerName
            AvailabilityGroupName = $WESqlAlwaysOnAvailabilityGroupName
            DomainNameFqdn = " ${SqlAlwaysOnAvailabilityGroupListenerName}.${DomainName}"
            ListenerPortNumber = $WEDatabaseEnginePort
            ProbePortNumber = $WEProbePortNumber
            ListenerIPAddress = $WEAGListenerIpAddress
            InstanceName = $env:COMPUTERNAME
            DomainCredential = $WEDomainCreds
            SqlAdministratorCredential = $WEAdmincreds
            PsDscRunAsCredential = $WEDomainCreds
            DependsOn = " [xSqlAvailabilityGroup]SqlAG"
        }

        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
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

function WE-Get-NetBIOSName
{ 
    [OutputType([string])]
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [string]$WEDomainName
    )

    if ($WEDomainName.Contains('.')) {
        $length=$WEDomainName.IndexOf('.')
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

function WE-Enable-CredSSPNTLM
{ 
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$true)]
        [string]$WEDomainName
    )
    
    # This is needed for the case where NTLM authentication is used

    Write-Verbose 'STARTED:Setting up CredSSP for NTLM'
   
    Enable-WSManCredSSP -Role client -DelegateComputer localhost, *.$WEDomainName -Force -ErrorAction SilentlyContinue
    Enable-WSManCredSSP -Role server -Force -ErrorAction SilentlyContinue

    if(-not (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -ErrorAction SilentlyContinue))
    {
        New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows -Name '\CredentialsDelegation' -ErrorAction SilentlyContinue
    }

    if( -not (Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name 'AllowFreshCredentialsWhenNTLMOnly' -ErrorAction SilentlyContinue))
    {
        New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name 'AllowFreshCredentialsWhenNTLMOnly' -value '1' -PropertyType dword -ErrorAction SilentlyContinue
    }

    if (-not (Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name 'ConcatenateDefaults_AllowFreshNTLMOnly' -ErrorAction SilentlyContinue))
    {
        New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name 'ConcatenateDefaults_AllowFreshNTLMOnly' -value '1' -PropertyType dword -ErrorAction SilentlyContinue
    }

    if(-not (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -ErrorAction SilentlyContinue))
    {
        New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name 'AllowFreshCredentialsWhenNTLMOnly' -ErrorAction SilentlyContinue
    }

    if (-not (Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name '1' -ErrorAction SilentlyContinue))
    {
        New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name '1' -value " wsman/$env:COMPUTERNAME" -PropertyType string -ErrorAction SilentlyContinue
    }

    if (-not (Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name '2' -ErrorAction SilentlyContinue))
    {
        New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name '2' -value " wsman/localhost" -PropertyType string -ErrorAction SilentlyContinue
    }

    if (-not (Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name '3' -ErrorAction SilentlyContinue))
    {
        New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name '3' -value " wsman/*.$WEDomainName" -PropertyType string -ErrorAction SilentlyContinue
    }

    Write-Verbose " DONE:Setting up CredSSP for NTLM"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================