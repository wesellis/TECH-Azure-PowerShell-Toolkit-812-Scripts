#Requires -Version 7.4
#Requires -Modules ComputerManagementDsc, NetworkingDsc, ActiveDirectoryDsc, SqlServerDsc, CertificateDsc

<#
.SYNOPSIS
    Configure SQL VM

.DESCRIPTION
    Azure DSC configuration for SQL Server VM setup

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

configuration ConfigureSQLVM
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$DNSServerIP,

        [Parameter(Mandatory = $true)]
        [String]$DomainFQDN,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$DomainAdminCreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SqlSvcCreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SPSetupCreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SPFarmCreds
    )

    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 10.0.0
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 9.0.0
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion 6.6.2
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 17.0.0
    Import-DscResource -ModuleName CertificateDsc -ModuleVersion 6.0.0

    [String]$DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    $Interface = Get-NetAdapter | Where-Object InterfaceDescription -Like "Microsoft Hyper-V Network Adapter*" | Select-Object -First 1
    [String]$InterfaceAlias = $Interface.Name
    [String]$ComputerName = Get-Content env:computername
    [System.Management.Automation.PSCredential]$DomainAdminCredsQualified = New-Object System.Management.Automation.PSCredential ("$DomainNetbiosName\$($DomainAdminCreds.UserName)", $DomainAdminCreds.Password)
    [System.Management.Automation.PSCredential]$SqlSvcCredsQualified = New-Object System.Management.Automation.PSCredential ("$DomainNetbiosName\$($SqlSvcCreds.UserName)", $SqlSvcCreds.Password)
    [System.Management.Automation.PSCredential]$SPSetupCredsQualified = New-Object System.Management.Automation.PSCredential ("$DomainNetbiosName\$($SPSetupCreds.UserName)", $SPSetupCreds.Password)
    [System.Management.Automation.PSCredential]$SPFarmCredsQualified = New-Object System.Management.Automation.PSCredential ("$DomainNetbiosName\$($SPFarmCreds.UserName)", $SPFarmCreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        WindowsFeature AddADTools
        {
            Name = "RSAT-AD-Tools"
            Ensure = "Present"
        }

        WindowsFeature AddADPowerShell
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        DnsServerAddress SetDNS
        {
            Address = $DNSServerIP
            InterfaceAlias = $InterfaceAlias
            AddressFamily = 'IPv4'
        }

        Script WaitForDomain
        {
            SetScript = {
                $DomainFQDN = $using:DomainFQDN
                $SleepTime = 15
                do {
                    try {
                        $domain = Get-ADDomain -Identity $DomainFQDN
                        if ($domain) {
                            break
                        }
                    }
                    catch {
                        Write-Verbose -Verbose -Message "Domain '$DomainFQDN' not found yet: $_"
                        Start-Sleep -Seconds $SleepTime
                    }
                } while ($true)
            }
            GetScript = { return @{ "Result" = "false" } }
            TestScript = {
                try {
                    Get-ADDomain -Identity $using:DomainFQDN
                    return $true
                } catch {
                    return $false
                }
            }
            DependsOn = "[WindowsFeature]AddADPowerShell", "[DnsServerAddress]SetDNS"
        }

        Computer JoinDomain
        {
            Name = $ComputerName
            DomainName = $DomainFQDN
            Credential = $DomainAdminCredsQualified
            DependsOn = "[Script]WaitForDomain"
        }

        PendingReboot RebootOnSignalFromJoinDomain
        {
            Name = "RebootOnSignalFromJoinDomain"
            SkipCcmClientSDK = $true
            DependsOn = "[Computer]JoinDomain"
        }

        Script WaitForSqlSetup
        {
            SetScript = {
                $SleepTime = 30
                do {
                    $SqlInstance = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
                    if ($SqlInstance -and $SqlInstance.Status -eq "Running") {
                        Write-Verbose -Verbose -Message "SQL Server is installed and running"
                        break
                    }
                    else {
                        Write-Verbose -Verbose -Message "SQL Server not ready yet, waiting..."
                        Start-Sleep -Seconds $SleepTime
                    }
                } while ($true)
            }
            GetScript = { }
            TestScript = {
                $SqlInstance = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
                return ($SqlInstance -and $SqlInstance.Status -eq "Running")
            }
            DependsOn = "[PendingReboot]RebootOnSignalFromJoinDomain"
        }

        SqlLogin AddDomainAdminAccountToSysadminServerRole
        {
            Name = $DomainAdminCredsQualified.UserName
            LoginType = "WindowsUser"
            ServerName = $ComputerName
            InstanceName = "MSSQLSERVER"
            DependsOn = "[Script]WaitForSqlSetup"
        }

        SqlLogin AddSPSetupAccountToSysadminServerRole
        {
            Name = $SPSetupCredsQualified.UserName
            LoginType = "WindowsUser"
            ServerName = $ComputerName
            InstanceName = "MSSQLSERVER"
            DependsOn = "[Script]WaitForSqlSetup"
        }

        SqlLogin AddSPFarmAccountToSysadminServerRole
        {
            Name = $SPFarmCredsQualified.UserName
            LoginType = "WindowsUser"
            ServerName = $ComputerName
            InstanceName = "MSSQLSERVER"
            DependsOn = "[Script]WaitForSqlSetup"
        }

        SqlRole GrantSysadminRoleToDomainAdmin
        {
            ServerRoleName = "sysadmin"
            MembersToInclude = $DomainAdminCredsQualified.UserName
            ServerName = $ComputerName
            InstanceName = "MSSQLSERVER"
            DependsOn = "[SqlLogin]AddDomainAdminAccountToSysadminServerRole"
        }

        SqlRole GrantSysadminRoleToSPSetup
        {
            ServerRoleName = "sysadmin"
            MembersToInclude = $SPSetupCredsQualified.UserName
            ServerName = $ComputerName
            InstanceName = "MSSQLSERVER"
            DependsOn = "[SqlLogin]AddSPSetupAccountToSysadminServerRole"
        }

        SqlRole GrantSysadminRoleToSPFarm
        {
            ServerRoleName = "sysadmin"
            MembersToInclude = $SPFarmCredsQualified.UserName
            ServerName = $ComputerName
            InstanceName = "MSSQLSERVER"
            DependsOn = "[SqlLogin]AddSPFarmAccountToSysadminServerRole"
        }

        SqlWindowsFirewall ConfigureSQLFirewall
        {
            Features = "SQLEngine"
            InstanceName = "MSSQLSERVER"
            SourcePath = "C:\SQLServerFull"
        }

        Script ConfigureSQLMaxDOP
        {
            SetScript = {
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
                $server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
                $server.Configuration.MaxDegreeOfParallelism.ConfigValue = 1
                $server.Configuration.Alter()
            }
            GetScript = { }
            TestScript = {
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
                $server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
                return $server.Configuration.MaxDegreeOfParallelism.ConfigValue -eq 1
            }
            DependsOn = "[Script]WaitForSqlSetup"
        }
    }
}

function Get-NetBIOSName {
    [OutputType([string])]
    param(
        [string]$DomainFQDN
    )

    if ($DomainFQDN.Contains('.')) {
        $length = $DomainFQDN.IndexOf('.')
        if ($length -ge 16) {
            $length = 15
        }
        return $DomainFQDN.Substring(0, $length)
    }
    else {
        if ($DomainFQDN.Length -gt 15) {
            return $DomainFQDN.Substring(0, 15)
        }
        else {
            return $DomainFQDN
        }
    }
}