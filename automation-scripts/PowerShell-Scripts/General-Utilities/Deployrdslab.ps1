<#
.SYNOPSIS
    We Enhanced Deployrdslab

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

Configuration CreateRootDomain
{
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Parameter(Mandatory)]
        [Array]$WERDSParameters
    )

    $WEDomainName = $WERDSParameters[0].DomainName
    $WEDNSServer = $WERDSParameters[0].DNSServer
    $WETimeZoneID = $WERDSParameters[0].TimeZoneID
    $WEExternalDnsDomain = $WERDSParameters[0].ExternalDnsDomain
    $WEIntBrokerLBIP = $WERDSParameters[0].IntBrokerLBIP
    $WEIntWebGWLBIP = $WERDSParameters[0].IntWebGWLBIP
    $WEWebGWDNS = $WERDSParameters[0].WebGWDNS
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration,xActiveDirectory,xNetworking,ComputerManagementDSC,xComputerManagement,xDnsServer,NetworkingDsc
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($WEAdmincreds.UserName)" ,$WEAdmincreds.Password)
    $WEInterface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $WEMyIP = ($WEInterface | Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1).IPAddress
    $WEInterfaceAlias = $($WEInterface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = " ApplyOnly"
        }
                
        WindowsFeature DNS
        {
            Ensure = " Present"
            Name = " DNS"
        }

        WindowsFeature AD-Domain-Services
        {
            Ensure = " Present"
            Name = " AD-Domain-Services"
            DependsOn = " [WindowsFeature]DNS"
        }      

        WindowsFeature DnsTools
        {
            Ensure = " Present"
            Name = " RSAT-DNS-Server"
            DependsOn = " [WindowsFeature]DNS"
        }        

        WindowsFeature GPOTools
        {
            Ensure = " Present"
            Name = " GPMC"
            DependsOn = " [WindowsFeature]DNS"
        }

        WindowsFeature DFSTools
        {
            Ensure = " Present"
            Name = " RSAT-DFS-Mgmt-Con"
            DependsOn = " [WindowsFeature]DNS"
        }        

        WindowsFeature RSAT-AD-Tools
        {
            Ensure = " Present"
            Name = " RSAT-AD-Tools"
            DependsOn = " [WindowsFeature]AD-Domain-Services"
            IncludeAllSubFeature = $WETrue
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone = $WETimeZoneID
        }

        Firewall EnableSMBFwRule
        {
            Name = " FPS-SMB-In-TCP"
            Enabled = $WETrue
            Ensure = " Present"
        }
        
        xDnsServerAddress DnsServerAddress
        {
            Address        = $WEDNSServer
            InterfaceAlias = $WEInterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn = " [WindowsFeature]DNS"
        }

        If ($WEMyIP -eq $WEDNSServer) {
            xADDomain RootDomain
            {
                DomainName = $WEDomainName
                DomainAdministratorCredential = $WEDomainCreds
                SafemodeAdministratorPassword = $WEDomainCreds
                DatabasePath = " $WEEnv:windir\NTDS"
                LogPath = " $WEEnv:windir\NTDS"
                SysvolPath = " $WEEnv:windir\SYSVOL"
                DependsOn = @(" [WindowsFeature]AD-Domain-Services", " [xDnsServerAddress]DnsServerAddress")
            }

            xDnsServerForwarder SetForwarders
            {
                IsSingleInstance = 'Yes'
                IPAddresses      = @('8.8.8.8', '8.8.4.4')
                UseRootHint      = $false
                DependsOn = @(" [WindowsFeature]DNS", " [xADDomain]RootDomain")
            }
    
            Script AddExternalZone
            {
                SetScript = {
                    Add-DnsServerPrimaryZone -Name $WEUsing:ExternalDnsDomain `
                        -ReplicationScope " Forest" `
                        -DynamicUpdate " Secure"
                }
    
                TestScript = {
                    If (Get-DnsServerZone -Name $WEUsing:ExternalDnsDomain -ErrorAction SilentlyContinue) {
                        Return $WETrue
                    } Else {
                        Return $WEFalse
                    }
                }
    
                GetScript = {
                    @{
                        Result = Get-DnsServerZone -Name $WEUsing:ExternalDnsDomain -ErrorAction SilentlyContinue
                    }
                }
    
                DependsOn = " [xDnsServerForwarder]SetForwarders"
            }
    
            xDnsRecord AddIntLBBrokerIP
            {
                Name = " broker"
                Target = $WEIntBrokerLBIP
                Zone = $WEExternalDnsDomain
                Type = " ARecord"
                Ensure = " Present"
                DependsOn = " [Script]AddExternalZone"
            }
    
            xDnsRecord AddIntLBWebGWIP
            {
                Name = $WEWebGWDNS
                Target = $WEIntWebGWLBIP
                Zone = $WEExternalDnsDomain
                Type = " ARecord"
                Ensure = " Present"
                DependsOn = " [Script]AddExternalZone"
            }

            PendingReboot RebootAfterInstallingAD
            {
                Name = 'RebootAfterInstallingAD'
                DependsOn = @(" [xADDomain]RootDomain"," [xDnsServerForwarder]SetForwarders")
            }                       
        } Else {            
            xWaitForADDomain DscForestWait
            {
                DomainName = $WEDomainName
                DomainUserCredential= $WEDomainCreds
                RetryCount = 30
                RetryIntervalSec = 2400
                DependsOn = @(" [WindowsFeature]AD-Domain-Services", " [xDnsServerAddress]DnsServerAddress")
            }
            
            xADDomainController NextDC
            {
                DomainName = $WEDomainName
                DomainAdministratorCredential = $WEDomainCreds
                SafemodeAdministratorPassword = $WEDomainCreds
                DatabasePath = " $WEEnv:windir\NTDS"
                LogPath = " $WEEnv:windir\NTDS"
                SysvolPath = " $WEEnv:windir\SYSVOL"
                DependsOn = @(" [xWaitForADDomain]DscForestWait"," [WindowsFeature]AD-Domain-Services", " [xDnsServerAddress]DnsServerAddress")
            }

            xDnsServerForwarder SetForwarders
            {
                IsSingleInstance = 'Yes'
                IPAddresses      = @('8.8.8.8', '8.8.4.4')
                UseRootHint      = $false
                DependsOn = @(" [WindowsFeature]DNS", " [xADDomainController]NextDC")
            }            

            PendingReboot RebootAfterInstallingAD
            {
                Name = 'RebootAfterInstallingAD'
                DependsOn = @(" [xADDomainController]NextDC"," [xDnsServerForwarder]SetForwarders")
            }            
        }        
    }
}

Configuration RDWebGateway
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Parameter(Mandatory)]
        [Array]$WERDSParameters
    )

    $WEDomainName = $WERDSParameters[0].DomainName
    $WEDNSServer = $WERDSParameters[0].DNSServer
    $WETimeZoneID = $WERDSParameters[0].TimeZoneID
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration,xNetworking,ActiveDirectoryDsc,ComputerManagementDSC,xComputerManagement,xWebAdministration,NetworkingDsc
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)",$WEAdmincreds.Password)
    $WEInterface = Get-NetAdapter | Where-Object Name -Like " Ethernet*" | Select-Object -First 1
    $WEInterfaceAlias = $($WEInterface.Name)

    Node localhost
    {    
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = " ApplyOnly"
        }

        WindowsFeature RDS-Gateway
        {
            Ensure = " Present"
            Name = " RDS-Gateway"
        }

        WindowsFeature RDS-Web-Access
        {
            Ensure = " Present"
            Name = " RDS-Web-Access"
        }

        WindowsFeature RSAT-AD-PowerShell
        {
            Ensure = " Present"
            Name = " RSAT-AD-PowerShell"
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone = $WETimeZoneID
        }

        Firewall EnableSMBFwRule
        {
            Name = " FPS-SMB-In-TCP"
            Enabled = $WETrue
            Ensure = " Present"
        }        
        
        xIISMimeTypeMapping ConfigureMIME
        {
            Extension = " ."
            MimeType = " text/plain"
            ConfigurationPath = " IIS:\sites\Default Web Site"
            Ensure = " Present"
            DependsOn = " [WindowsFeature]RDS-Web-Access"
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = $WEDNSServer
            InterfaceAlias = $WEInterfaceAlias
            AddressFamily  = 'IPv4'
        }

        WaitForADDomain WaitADDomain
        {
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            WaitTimeout = 2400
            RestartCount = 30
            WaitForValidCredentials = $WETrue
            DependsOn = @(" [xDnsServerAddress]DnsServerAddress"," [WindowsFeature]RSAT-AD-PowerShell")
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            DependsOn = " [WaitForADDomain]WaitADDomain" 
        }
    }
}

Configuration RDSessionHost
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Parameter(Mandatory)]
        [Array]$WERDSParameters
    )

    $WEDomainName = $WERDSParameters[0].DomainName
    $WEDNSServer = $WERDSParameters[0].DNSServer
    $WETimeZoneID = $WERDSParameters[0].TimeZoneID
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration,xNetworking,ActiveDirectoryDsc,ComputerManagementDSC,xComputerManagement,NetworkingDsc
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)",$WEAdmincreds.Password)
    $WEInterface = Get-NetAdapter | Where-Object Name -Like " Ethernet*" | Select-Object -First 1
    $WEInterfaceAlias = $($WEInterface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = " ApplyOnly"
        }

        WindowsFeature RDS-RD-Server
        {
            Ensure = " Present"
            Name = " RDS-RD-Server"
        }

        WindowsFeature RSAT-AD-PowerShell
        {
            Ensure = " Present"
            Name = " RSAT-AD-PowerShell"
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone = $WETimeZoneID
        }
        
        Firewall EnableSMBFwRule
        {
            Name = " FPS-SMB-In-TCP"
            Enabled = $WETrue
            Ensure = " Present"
        }        

        xDnsServerAddress DnsServerAddress
        {
            Address        = $WEDNSServer
            InterfaceAlias = $WEInterfaceAlias
            AddressFamily  = 'IPv4'
        }

        WaitForADDomain WaitADDomain
        {
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            WaitTimeout = 2400
            RestartCount = 30
            WaitForValidCredentials = $WETrue
            DependsOn = @(" [xDnsServerAddress]DnsServerAddress"," [WindowsFeature]RSAT-AD-PowerShell")
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            DependsOn = " [WaitForADDomain]WaitADDomain" 
        }        
    }    
}

Configuration RDLicenseServer
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Parameter(Mandatory)]
        [Array]$WERDSParameters
    )

    $WEDomainName = $WERDSParameters[0].DomainName
    $WEDNSServer = $WERDSParameters[0].DNSServer
    $WETimeZoneID = $WERDSParameters[0].TimeZoneID
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration,xNetworking,ActiveDirectoryDsc,ComputerManagementDSC,xComputerManagement,NetworkingDsc
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)",$WEAdmincreds.Password)
    $WEInterface = Get-NetAdapter | Where-Object Name -Like " Ethernet*" | Select-Object -First 1
    $WEInterfaceAlias = $($WEInterface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = " ApplyOnly"
        }

        WindowsFeature RDS-Licensing
        {
            Ensure = " Present"
            Name = " RDS-Licensing"
        }

        WindowsFeature RSAT-AD-PowerShell
        {
            Ensure = " Present"
            Name = " RSAT-AD-PowerShell"
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone = $WETimeZoneID
        }

        Firewall EnableSMBFwRule
        {
            Name = " FPS-SMB-In-TCP"
            Enabled = $WETrue
            Ensure = " Present"
        }        

        xDnsServerAddress DnsServerAddress
        {
            Address        = $WEDNSServer
            InterfaceAlias = $WEInterfaceAlias
            AddressFamily  = 'IPv4'
        }

        WaitForADDomain WaitADDomain
        {
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            WaitTimeout = 2400
            RestartCount = 30
            WaitForValidCredentials = $WETrue
            DependsOn = @(" [xDnsServerAddress]DnsServerAddress"," [WindowsFeature]RSAT-AD-PowerShell")
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            DependsOn = " [WaitForADDomain]WaitADDomain" 
        }        
    }    
}

Configuration RDSDeployment
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Parameter(Mandatory)]
        [Array]$WERDSParameters
    )

    $WEDomainName = $WERDSParameters[0].DomainName
    $WEDNSServer = $WERDSParameters[0].DNSServer
    $WETimeZoneID = $WERDSParameters[0].TimeZoneID
    $WEMainConnectionBroker = $($WERDSParameters[0].MainConnectionBroker + " ." + $WEDomainName)
    $WEWebAccessServer = $($WERDSParameters[0].WebAccessServer + " ." + $WEDomainName)
    $WESessionHost = $($WERDSParameters[0].SessionHost + " ." + $WEDomainName)
    $WELicenseServer = $($WERDSParameters[0].LicenseServer + " ." + $WEDomainName)
    $WEExternalFqdn = $WERDSParameters[0].ExternalFqdn

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xNetworking,ActiveDirectoryDsc,ComputerManagementDSC,xComputerManagement,xRemoteDesktopSessionHost,NetworkingDsc
    [System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)",$WEAdmincreds.Password)
    $WEInterface = Get-NetAdapter | Where-Object Name -Like " Ethernet*" | Select-Object -First 1
    $WEInterfaceAlias = $($WEInterface.Name)

    if (-not $collectionName)         { $collectionName = " RemoteApps" }
    if (-not $collectionDescription)  {;  $collectionDescription = " Remote Desktop Services Apps" }

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = " ApplyOnly"
        }

        WindowsFeature RSAT-RDS-Tools
        {
            Ensure = " Present"
            Name = " RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }        

        WindowsFeature RSAT-AD-PowerShell
        {
            Ensure = " Present"
            Name = " RSAT-AD-PowerShell"
        }

        WindowsFeature RDS-Connection-Broker
        {
            Ensure = " Present"
            Name = " RDS-Connection-Broker"
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone = $WETimeZoneID
        }        

        Firewall EnableSMBFwRule
        {
            Name = " FPS-SMB-In-TCP"
            Enabled = $WETrue
            Ensure = " Present"
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = $WEDNSServer
            InterfaceAlias = $WEInterfaceAlias
            AddressFamily  = 'IPv4'
        }

        WaitForADDomain WaitADDomain
        {
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            WaitTimeout = 2400
            RestartCount = 30
            WaitForValidCredentials = $WETrue
            DependsOn = @(" [xDnsServerAddress]DnsServerAddress"," [WindowsFeature]RSAT-AD-PowerShell")
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $WEDomainName
            Credential = $WEDomainCreds
            DependsOn = " [WaitForADDomain]WaitADDomain" 
        }

        Registry RdmsEnableUILog
        {
            Ensure = " Present"
            Key = " HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = " EnableUILog"
            ValueType = " Dword"
            ValueData = " 1"
        }
 
        Registry EnableDeploymentUILog
        {
            Ensure = " Present"
            Key = " HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = " EnableDeploymentUILog"
            ValueType = " Dword"
            ValueData = " 1"
        }
 
        Registry EnableTraceLog
        {
            Ensure = " Present"
            Key = " HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = " EnableTraceLog"
            ValueType = " Dword"
            ValueData = " 1"
        }
 
        Registry EnableTraceToFile
        {
            Ensure = " Present"
            Key = " HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = " EnableTraceToFile"
            ValueType = " Dword"
            ValueData = " 1"
        }

        If ($($WEEnv:COMPUTERNAME) -eq $($WERDSParameters[0].MainConnectionBroker)) {
            xRDSessionDeployment Deployment
            {
                ConnectionBroker = $WEMainConnectionBroker
                WebAccessServer = $WEWebAccessServer
                SessionHost = $WESessionHost
                PsDscRunAsCredential = $WEDomainCreds
                DependsOn = " [xComputer]DomainJoin"
            }

            xRDServer AddLicenseServer
            {
                Role = 'RDS-Licensing'
                Server = $WELicenseServer
                PsDscRunAsCredential = $WEDomainCreds
                DependsOn = " [xRDSessionDeployment]Deployment"
            }
            
            xRDLicenseConfiguration LicenseConfiguration
            {
                ConnectionBroker = $WEMainConnectionBroker
                LicenseServer = $WELicenseServer
                LicenseMode = 'PerUser'
                PsDscRunAsCredential = $WEDomainCreds
                DependsOn = " [xRDServer]AddLicenseServer"
            }
                
            xRDServer AddGatewayServer
            {
                Role = 'RDS-Gateway'
                Server = $WEWebAccessServer
                GatewayExternalFqdn = $WEExternalFqdn
                PsDscRunAsCredential = $WEDomainCreds
                DependsOn = " [xRDLicenseConfiguration]LicenseConfiguration"
            }

            xRDGatewayConfiguration GatewayConfiguration
            {
                ConnectionBroker = $WEMainConnectionBroker
                GatewayServer = $WEWebAccessServer
                ExternalFqdn = $WEExternalFqdn
                GatewayMode = 'Custom'
                LogonMethod = 'Password'
                UseCachedCredentials = $true
                BypassLocal = $false
                PsDscRunAsCredential = $WEDomainCreds
                DependsOn = " [xRDServer]AddGatewayServer"
            }
            
            xRDSessionCollection Collection
            {
                ConnectionBroker = $WEMainConnectionBroker
                CollectionName = $WECollectionName
                CollectionDescription = $WECollectionDescription
                SessionHost = $WESessionHost
                PsDscRunAsCredential = $WEDomainCreds
                DependsOn = " [xRDGatewayConfiguration]GatewayConfiguration"
            }
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
