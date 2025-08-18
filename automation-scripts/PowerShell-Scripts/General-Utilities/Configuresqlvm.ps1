<#
.SYNOPSIS
    Configuresqlvm

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
    We Enhanced Configuresqlvm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


configuration ConfigureSQLVM
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)] [String]$WEDNSServerIP,
        [Parameter(Mandatory)] [String]$WEDomainFQDN,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WEDomainAdminCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESqlSvcCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPSetupCreds
    )

    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 10.0.0 # Custom
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 9.0.0
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion 6.6.2
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 17.0.0 # Custom workaround on SqlSecureConnection
    Import-DscResource -ModuleName CertificateDsc -ModuleVersion 6.0.0

    WaitForSqlSetup
    [String] $WEDomainNetbiosName = (Get-NetBIOSName -DomainFQDN $WEDomainFQDN)
    $WEInterface = Get-NetAdapter| Where-Object InterfaceDescription -Like " Microsoft Hyper-V Network Adapter*" | Select-Object -First 1
    $WEInterfaceAlias = $($WEInterface.Name)
    
    # Format credentials to be qualified by domain name: " domain\username"
    [System.Management.Automation.PSCredential] $WEDomainAdminCredsQualified = New-Object System.Management.Automation.PSCredential (" $WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)" , $WEDomainAdminCreds.Password)
    [System.Management.Automation.PSCredential] $WESQLCredsQualified = New-Object PSCredential (" ${DomainNetbiosName}\$($WESqlSvcCreds.UserName)" , $WESqlSvcCreds.Password)
    [String];  $WEComputerName = Get-Content env:computername
    [String];  $WEAdfsDnsEntryName = " adfs"

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        #**********************************************************
        # Initialization of VM - Do as much work as possible before waiting on AD domain to be available
        #**********************************************************
        WindowsFeature AddADTools      { Name = " RSAT-AD-Tools" ;      Ensure = " Present" ; }
        WindowsFeature AddADPowerShell { Name = " RSAT-AD-PowerShell" ; Ensure = " Present" ; }
        
        DnsServerAddress SetDNS { Address = $WEDNSServerIP; InterfaceAlias = $WEInterfaceAlias; AddressFamily  = 'IPv4' }
        

        Script EnableFileSharing {
            GetScript  = { }
            TestScript = { return $null -ne (Get-NetFirewallRule -DisplayGroup " File And Printer Sharing" -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.Profile -eq " Domain" }) }
            SetScript  = { Set-NetFirewallRule -DisplayGroup " File And Printer Sharing" -Enabled True -Profile Domain }
        }

        Script EnableRemoteEventViewerConnection {
            GetScript  = { }
            TestScript = { return $null -ne (Get-NetFirewallRule -DisplayGroup " Remote Event Log Management" -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.Profile -eq " Domain" }) }
            SetScript  = { Set-NetFirewallRule -DisplayGroup " Remote Event Log Management" -Enabled True -Profile Domain }
        }

        #**********************************************************
        # Join AD forest
        #**********************************************************
        # DNS record for ADFS is created only after the ADFS farm was created and DC restarted (required by ADFS setup)
        # This turns out to be a very reliable way to ensure that VM joins AD only when the DC is guaranteed to be ready
        # This totally eliminates the random errors that occured in WaitForADDomain with the previous logic (and no more need of WaitForADDomain)
        Script WaitForADFSFarmReady
        {
            SetScript =
            {
                $dnsRecordFQDN = " $($using:AdfsDnsEntryName).$($using:DomainFQDN)"
                $dnsRecordFound = $false
               ;  $sleepTime = 15
                do {
                    try {
                        [Net.DNS]::GetHostEntry($dnsRecordFQDN)
                       ;  $dnsRecordFound = $true
                    }
                    catch [System.Net.Sockets.SocketException] {
                        # GetHostEntry() throws SocketException " No such host is known" if DNS entry is not found
                        Write-Verbose -Verbose -Message " DNS record '$dnsRecordFQDN' not found yet: $_"
                        Start-Sleep -Seconds $sleepTime
                    }
                } while ($false -eq $dnsRecordFound)
            }
            GetScript            = { return @{ " Result" = " false" } } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript           = { try { [Net.DNS]::GetHostEntry(" $($using:AdfsDnsEntryName).$($using:DomainFQDN)" ); return $true } catch { return $false } }
            DependsOn            = " [DnsServerAddress]SetDNS"
        }

        # # If WaitForADDomain does not find the domain whtin " WaitTimeout" secs, it will signar a restart to DSC engine " RestartCount" times
        # WaitForADDomain WaitForDCReady
        # {
        #     DomainName              = $WEDomainFQDN
        #     WaitTimeout             = 1800
        #     RestartCount            = 2
        #     WaitForValidCredentials = $WETrue
        #     Credential              = $WEDomainAdminCredsQualified
        #     DependsOn               = " [Script]WaitForADFSFarmReady"
        # }

        # # WaitForADDomain sets reboot signal only if WaitForADDomain did not find domain within " WaitTimeout" secs
        # PendingReboot RebootOnSignalFromWaitForDCReady
        # {
        #     Name             = " RebootOnSignalFromWaitForDCReady"
        #     SkipCcmClientSDK = $true
        #     DependsOn        = " [WaitForADDomain]WaitForDCReady"
        # }

        Computer JoinDomain
        {
            Name       = $WEComputerName
            DomainName = $WEDomainFQDN
            Credential = $WEDomainAdminCredsQualified
            # DependsOn  = " [PendingReboot]RebootOnSignalFromWaitForDCReady"
            DependsOn  = " [Script]WaitForADFSFarmReady"
        }

        PendingReboot RebootOnSignalFromJoinDomain
        {
            Name             = " RebootOnSignalFromJoinDomain"
            SkipCcmClientSDK = $true
            DependsOn        = " [Computer]JoinDomain"
        }

        #**********************************************************
        # Create accounts and configure SQL Server
        #**********************************************************
        # By default, SPNs MSSQLSvc/SQL.contoso.local:1433 and MSSQLSvc/SQL.contoso.local are set on the machine account
        # They need to be removed before they can be set on the SQL service account
        Script RemoveSQLSpnOnSQLMachine
        {
            GetScript = { }
            TestScript = { return $false }
            SetScript = 
            {
                $hostname = $using:ComputerName
               ;  $domainFQDN = $using:DomainFQDN
                setspn -D " MSSQLSvc/$hostname.$($domainFQDN)" " $hostname"
                setspn -D " MSSQLSvc/$hostname.$($domainFQDN):1433" " $hostname"
            }
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        ADUser CreateSqlSvcAccount
        {
            DomainName           = $WEDomainFQDN
            UserName             = $WESqlSvcCreds.UserName
            UserPrincipalName    = " $($WESqlSvcCreds.UserName)@$WEDomainFQDN"
            Password             = $WESQLCredsQualified
            PasswordNeverExpires = $true
            ServicePrincipalNames = @(" MSSQLSvc/$WEComputerName.$($WEDomainFQDN):1433" , " MSSQLSvc/$WEComputerName.$WEDomainFQDN" , " MSSQLSvc/$($WEComputerName):1433" , " MSSQLSvc/$WEComputerName" )
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RemoveSQLSpnOnSQLMachine"
        }

        Script EnsureSQLServiceStarted
        {
            GetScript = { }
            TestScript = { return (Get-Service -Name " MSSQLSERVER" ).Status -like 'Running' }
            SetScript = { Start-Service -Name " MSSQLSERVER" }
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        SqlMaxDop ConfigureMaxDOP { ServerName = $WEComputerName; InstanceName = " MSSQLSERVER" ; MaxDop = 1; DependsOn = " [Script]EnsureSQLServiceStarted" }

        # Script WorkaroundErrorInSqlServiceAccountResource
        # {
        #     GetScript = { }
        #     TestScript = { return $false }
        #     SetScript = { 
        #         [reflection.assembly]::LoadWithPartialName(" Microsoft.SqlServer.SqlWmiManagement" )
        #         $mc = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
        #     }
        #     DependsOn      = " [Script]EnsureSQLServiceStarted" , " [ADUser]CreateSqlSvcAccount"
        #     PsDscRunAsCredential = $WEDomainAdminCredsQualified
        # }

        SqlServiceAccount SetSqlInstanceServiceAccount
        {
            ServerName     = $WEComputerName
            InstanceName   = " MSSQLSERVER"
            ServiceType    = " DatabaseEngine"
            ServiceAccount = $WESQLCredsQualified
            RestartService = $true
            DependsOn      = " [Script]EnsureSQLServiceStarted" , " [ADUser]CreateSqlSvcAccount"
            # DependsOn      = " [Script]WorkaroundErrorInSqlServiceAccountResource"
        }

        SqlLogin AddDomainAdminLogin
        {
            Name         = " ${DomainNetbiosName}\$($WEDomainAdminCreds.UserName)"
            Ensure       = " Present"
            ServerName   = $WEComputerName
            InstanceName = " MSSQLSERVER"
            LoginType    = " WindowsUser"
            DependsOn    = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        ADUser CreateSPSetupAccount
        {   # Both SQL and SharePoint DSCs run this SPSetupAccount AD account creation
            DomainName           = $WEDomainFQDN
            UserName             = $WESPSetupCreds.UserName
            UserPrincipalName    = " $($WESPSetupCreds.UserName)@$WEDomainFQDN"
            Password             = $WESPSetupCreds
            PasswordNeverExpires = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        SqlLogin AddSPSetupLogin
        {
            Name         = " ${DomainNetbiosName}\$($WESPSetupCreds.UserName)"
            Ensure       = " Present"
            ServerName   = $WEComputerName
            InstanceName = " MSSQLSERVER"
            LoginType    = " WindowsUser"
            DependsOn    = " [ADUser]CreateSPSetupAccount"
        }

        SqlRole GrantSQLRoleSysadmin
        {
            ServerRoleName   = " sysadmin"
            MembersToInclude = @(" ${DomainNetbiosName}\$($WEDomainAdminCreds.UserName)" )
            ServerName       = $WEComputerName
            InstanceName     = " MSSQLSERVER"
            Ensure           = " Present"
            DependsOn        = " [SqlLogin]AddDomainAdminLogin"
        }

        SqlRole GrantSQLRoleSecurityAdmin
        {
            ServerRoleName   = " securityadmin"
            MembersToInclude = @(" ${DomainNetbiosName}\$($WESPSetupCreds.UserName)" )
            ServerName       = $WEComputerName
            InstanceName     = " MSSQLSERVER"
            Ensure           = " Present"
            DependsOn        = " [SqlLogin]AddSPSetupLogin"
        }

        SqlRole GrantSQLRoleDBCreator
        {
            ServerRoleName   = " dbcreator"
            MembersToInclude = @(" ${DomainNetbiosName}\$($WESPSetupCreds.UserName)" )
            ServerName       = $WEComputerName
            InstanceName     = " MSSQLSERVER"
            Ensure           = " Present"
            DependsOn        = " [SqlLogin]AddSPSetupLogin"
        }

        # Since SharePointDsc 4.4.0, SPFarm " Switched from creating a Lock database to a Lock table in the TempDB. This to allow the use of precreated databases."
        # But for this to work, the SPSetup account needs specific permissions on both the tempdb and the dbo schema
        SqlDatabaseUser AddSPSetupUserToTempdb
        {
            ServerName           = $WEComputerName
            InstanceName         = " MSSQLSERVER"
            DatabaseName         = " tempdb"
            UserType             = 'Login'
            Name                 = " ${DomainNetbiosName}\$($WESPSetupCreds.UserName)"
            LoginName            = " ${DomainNetbiosName}\$($WESPSetupCreds.UserName)"
            DependsOn            = " [SqlLogin]AddSPSetupLogin"
        }

        # Reference: https://learn.microsoft.com/en-us/sql/t-sql/statements/grant-schema-permissions-transact-sql?view=sql-server-ver16
        SqlDatabasePermission GrantPermissionssToTempdb
        {
            Name                 = " ${DomainNetbiosName}\$($WESPSetupCreds.UserName)"
            ServerName           =  $WEComputerName
            InstanceName         = " MSSQLSERVER"
            DatabaseName         = " tempdb"
            Permission   = @(
                DatabasePermission
                {
                    State      = 'Grant'
                    Permission = @('Select', 'CreateTable', 'Execute', 'DELETE', 'INSERT', 'UPDATE')
                }
                DatabasePermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                DatabasePermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )
            DependsOn            = " [SqlDatabaseUser]AddSPSetupUserToTempdb"
        }

        SqlDatabaseObjectPermission GrantPermissionssToDboSchema
        {
            Name                 = " ${DomainNetbiosName}\$($WESPSetupCreds.UserName)"
            ServerName           = $WEComputerName
            InstanceName         = " MSSQLSERVER"
            DatabaseName         = " tempdb"
            SchemaName           = " dbo"
            ObjectName           = ""
            ObjectType           = " Schema"
            Permission           = @(
                DSC_DatabaseObjectPermission
                {
                    State      = " Grant"
                    Permission = " Select"
                }
                DSC_DatabaseObjectPermission
                {
                    State      = " Grant"
                    Permission = " Update"
                }
                DSC_DatabaseObjectPermission
                {
                    State      = " Grant"
                    Permission = " Insert"
                }
                DSC_DatabaseObjectPermission
                {
                    State      = " Grant"
                    Permission = " Execute"
                }
                DSC_DatabaseObjectPermission
                {
                    State      = " Grant"
                    Permission = " Control"
                }
                DSC_DatabaseObjectPermission
                {
                    State      = " Grant"
                    Permission = " References"
                }
            )
            DependsOn            = " [SqlDatabaseUser]AddSPSetupUserToTempdb"
        }

        # SqlDatabaseRole 'GrantPermissionsToTempdb'
        # {
        #     ServerName           = $WEComputerName
        #     InstanceName         = " MSSQLSERVER"
        #     DatabaseName         = " tempdb"
        #     Name                 = " db_owner"
        #     Ensure               = " Present"
        #     MembersToInclude     = @(" ${DomainNetbiosName}\$($WESPSetupCreds.UserName)" )
        #     PsDscRunAsCredential = $WESqlAdministratorCredential
        #     DependsOn            = " [SqlLogin]AddSPSetupLogin"
        # }

        # Update GPO to ensure the root certificate of the CA is present in " cert:\LocalMachine\Root\" , otherwise certificate request will fail
        # $WEDCServerName = Get-ADDomainController | Select-Object -First 1 -Expand Name
        $WEDCServerName = " DC"
        Script UpdateGPOToTrustRootCACert {
            SetScript            =
            {
                gpupdate.exe /force
            }
            GetScript            = { }
            TestScript           = 
            {
                $domainNetbiosName = $using:DomainNetbiosName
                $dcName = $using:DCServerName
                $rootCAName = " $domainNetbiosName-$dcName-CA"
                $cert = Get-ChildItem -Path " cert:\LocalMachine\Root\" -DnsName " $rootCAName"
                
                if ($null -eq $cert) {
                    return $false   # Run SetScript
                }
                else {
                    return $true    # Root CA already present
                }
            }
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        CertReq GenerateSQLServerCertificate {
            CARootName          = " $WEDomainNetbiosName-$WEDCServerName-CA"
            CAServerFQDN        = " $WEDCServerName.$WEDomainFQDN"
            Subject             = " $WEComputerName.$WEDomainFQDN"
            FriendlyName        = " SQL Server Certificate"
            KeyLength           = '2048'
            Exportable          = $true
            SubjectAltName      = " dns=$WEComputerName.$WEDomainFQDN&dns=$WEComputerName"
            ProviderName        = '" Microsoft RSA SChannel Cryptographic Provider" '
            OID                 = '1.3.6.1.5.5.7.3.1'
            KeyUsage            = 'CERT_KEY_ENCIPHERMENT_KEY_USAGE | CERT_DIGITAL_SIGNATURE_KEY_USAGE'
            CertificateTemplate = 'WebServer'
            AutoRenew           = $true
            Credential          = $WEDomainAdminCredsQualified
            DependsOn           = '[Script]UpdateGPOToTrustRootCACert'
        }

        $sqlsvcUserName = $WESQLCredsQualified.UserName
        Script GrantSqlsvcFullControlToPrivateKey {
            SetScript            = 
            {
                $subjectName = " CN=$($using:ComputerName).$($using:DomainFQDN)"
                $sqlsvcUserName = $using:sqlsvcUserName

                # Grant access to the certificate private key.
                $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -eq $subjectName }
                $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
                $fileName = $rsaCert.key.UniqueName
                $path = " $env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$fileName"
                $permissions = Get-Acl -Path $path
                $access_rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sqlsvcUserName, 'FullControl', 'None', 'None', 'Allow')
                $permissions.AddAccessRule($access_rule)
                Set-Acl -Path $path -AclObject $permissions
            }
            GetScript            =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ " Result" = " false" }
            }
            TestScript           = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn            = " [CertReq]GenerateSQLServerCertificate"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        # $subjectName = " CN=SQL.contoso.local"
        # $sqlServerEncryptionCertThumbprint = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -eq " CN=$WEComputerName.$WEDomainFQDN" } | Select-Object -Expand Thumbprint
        SqlSecureConnection EnableSecureConnection
        {
            InstanceName    = 'MSSQLSERVER'
            Thumbprint      = " CN=SQL.contoso.local"
            ForceEncryption = $false
            Ensure          = 'Present'
            ServiceAccount  = $WESqlSvcCreds.UserName
            ServerName      = " $WEComputerName.$WEDomainFQDN"
            DependsOn       = '[Script]GrantSqlsvcFullControlToPrivateKey'
        }

        # Open port on the firewall only when everything is ready, as SharePoint DSC is testing it to start creating the farm
        Firewall AddDatabaseEngineFirewallRule
        {
            Direction   = " Inbound"
            Name        = " SQL-Server-Database-Engine-TCP-In"
            DisplayName = " SQL Server Database Engine (TCP-In)"
            Description = " Inbound rule for SQL Server to allow TCP traffic for the Database Engine."
            Group       = " SQL Server"
            Enabled     = " True"
            Protocol    = " TCP"
            LocalPort   = " 1433"
            Ensure      = " Present"
        }
    }
}

function WE-Get-NetBIOSName
{
    [OutputType([string])]
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [string]$WEDomainFQDN
    )

    if ($WEDomainFQDN.Contains('.')) {
        $length=$WEDomainFQDN.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $WEDomainFQDN.Substring(0,$length)
    }
    else {
        if ($WEDomainFQDN.Length -gt 15) {
            return $WEDomainFQDN.Substring(0,15)
        }
        else {
            return $WEDomainFQDN
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



<#
$password = ConvertTo-SecureString -String " mytopsecurepassword" -AsPlainText -Force
$WEDomainAdminCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " yvand" , $password
$WESqlSvcCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " sqlsvc" , $password
$WESPSetupCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spsetup" , $password
$WEDNSServerIP = " 10.1.1.4"; 
$WEDomainFQDN = " contoso.local"
; 
$outputPath = " C:\Packages\Plugins\Microsoft.Powershell.DSC\2.83.5\DSCWork\ConfigureSQLVM.0\ConfigureSQLVM"
ConfigureSQLVM -DNSServerIP $WEDNSServerIP -DomainFQDN $WEDomainFQDN -DomainAdminCreds $WEDomainAdminCreds -SqlSvcCreds $WESqlSvcCreds -SPSetupCreds $WESPSetupCreds -ConfigurationData @{AllNodes=@(@{ NodeName=" localhost" ; PSDscAllowPlainTextPassword=$true })} -OutputPath $outputPath
Start-DscConfiguration -Path $outputPath -Wait -Verbose -Force




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================