#Requires -Version 7.4
#Requires -Modules ComputerManagementDsc, NetworkingDsc, ActiveDirectoryDsc, WebAdministrationDsc, SharePointDsc, DnsServerDsc, CertificateDsc, SqlServerDsc, cChoco, StorageDsc, xPSDesiredStateConfiguration

<#
.SYNOPSIS
    Configure Front End VM for SharePoint SE

.DESCRIPTION
    Azure DSC configuration for SharePoint front-end VM setup in SE mode

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

configuration ConfigureFEVM
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$DNSServerIP,

        [Parameter(Mandatory = $true)]
        [String]$DomainFQDN,

        [Parameter(Mandatory = $true)]
        [String]$DCServerName,

        [Parameter(Mandatory = $true)]
        [String]$SQLServerName,

        [Parameter(Mandatory = $true)]
        [String]$SQLAlias,

        [Parameter(Mandatory = $true)]
        [String]$SharePointVersion,

        [Parameter(Mandatory = $true)]
        [String]$SharePointSitesAuthority,

        [Parameter(Mandatory = $true)]
        [Boolean]$EnableAnalysis,

        [Parameter(Mandatory = $true)]
        [System.Object[]]$SharePointBits,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$DomainAdminCreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SPSetupCreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SPFarmCreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SPPassphraseCreds
    )

    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 10.0.0
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 9.0.0
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion 6.6.2
    Import-DscResource -ModuleName WebAdministrationDsc -ModuleVersion 4.2.1
    Import-DscResource -ModuleName SharePointDsc -ModuleVersion 5.6.1
    Import-DscResource -ModuleName DnsServerDsc -ModuleVersion 3.0.0
    Import-DscResource -ModuleName CertificateDsc -ModuleVersion 6.0.0
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 17.0.0
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.6.0.0
    Import-DscResource -ModuleName StorageDsc -ModuleVersion 6.0.1
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 9.2.1

    [String]$InterfaceAlias = (Get-NetAdapter | Where-Object InterfaceDescription -Like "Microsoft Hyper-V Network Adapter*" | Select-Object -First 1).Name
    [String]$ComputerName = Get-Content env:computername
    [String]$DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainAdminCredsQualified = New-Object System.Management.Automation.PSCredential ("$DomainNetbiosName\$($DomainAdminCreds.UserName)", $DomainAdminCreds.Password)
    [System.Management.Automation.PSCredential]$SPSetupCredsQualified = New-Object System.Management.Automation.PSCredential ("$DomainNetbiosName\$($SPSetupCreds.UserName)", $SPSetupCreds.Password)
    [System.Management.Automation.PSCredential]$SPFarmCredsQualified = New-Object System.Management.Automation.PSCredential ("$DomainNetbiosName\$($SPFarmCreds.UserName)", $SPFarmCreds.Password)
    [String]$SetupPath = "C:\DSC Data"
    [String]$DCSetupPath = "\\$DCServerName\C$\DSC Data"
    [String]$DscStatusFilePath = "$SetupPath\dsc-status-$ComputerName.log"
    [String]$AdfsDnsEntryName = "adfs"
    [String]$SPDBPrefix = "SPDSC_"
    [String]$AppDomainIntranetFQDN = "{0}{1}.{2}" -f $DomainFQDN.Split('.')[0], "Apps-Intranet", $DomainFQDN.Split('.')[1]
    [String]$MySiteHostAlias = "OhMy"
    [String]$HNSC1Alias = "HNSC1"

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        Script DscStatus_Start
        {
            SetScript = {
                $DestinationFolder = $using:SetupPath
                if (!(Test-Path $DestinationFolder -PathType Container)) {
                    New-Item -ItemType Directory -Force -Path $DestinationFolder
                }
                "$(Get-Date -Format u)`t$($using:ComputerName)`tDSC Configuration starting..." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript = { }
            TestScript = { return $false }
        }

        cChocoInstaller InstallChoco
        {
            InstallDir = "C:\Chocolatey"
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

        WindowsFeature AddDnsTools
        {
            Name = "RSAT-DNS-Server"
            Ensure = "Present"
        }

        DnsServerAddress SetDNS
        {
            Address = $DNSServerIP
            InterfaceAlias = $InterfaceAlias
            AddressFamily = 'IPv4'
        }

        Registry DisableLoopBackCheck
        {
            Key = "HKLM:\System\CurrentControlSet\Control\Lsa"
            ValueName = "DisableLoopbackCheck"
            ValueData = "1"
            ValueType = "Dword"
            Ensure = "Present"
        }

        SqlAlias AddSqlAlias
        {
            Ensure = "Present"
            Name = $SQLAlias
            ServerName = $SQLServerName
            Protocol = "TCP"
            TcpPort = 1433
        }

        Script EnableFileSharing
        {
            GetScript = { }
            TestScript = {
                return $null -ne (Get-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.Profile -eq "Domain" })
            }
            SetScript = {
                Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True -Profile Domain
            }
        }

        Script WaitForADFSFarmReady
        {
            SetScript = {
                $DnsRecordFQDN = "$($using:AdfsDnsEntryName).$($using:DomainFQDN)"
                $DnsRecordFound = $false
                $SleepTime = 15
                do {
                    try {
                        [Net.DNS]::GetHostEntry($DnsRecordFQDN)
                        $DnsRecordFound = $true
                    }
                    catch [System.Net.Sockets.SocketException] {
                        Write-Verbose -Verbose -Message "DNS record '$DnsRecordFQDN' not found yet: $_"
                        Start-Sleep -Seconds $SleepTime
                    }
                } while ($false -eq $DnsRecordFound)
            }
            GetScript = { return @{ "Result" = "false" } }
            TestScript = {
                try {
                    [Net.DNS]::GetHostEntry("$($using:AdfsDnsEntryName).$($using:DomainFQDN)")
                    return $true
                } catch {
                    return $false
                }
            }
            DependsOn = "[DnsServerAddress]SetDNS"
        }

        Computer JoinDomain
        {
            Name = $ComputerName
            DomainName = $DomainFQDN
            Credential = $DomainAdminCredsQualified
            DependsOn = "[Script]WaitForADFSFarmReady"
        }

        PendingReboot RebootOnSignalFromJoinDomain
        {
            Name = "RebootOnSignalFromJoinDomain"
            SkipCcmClientSDK = $true
            DependsOn = "[Computer]JoinDomain"
        }

        Script CreateWSManSPNsIfNeeded
        {
            SetScript = {
                $DomainFQDN = $using:DomainFQDN
                $ComputerName = $using:ComputerName
                Write-Verbose -Verbose -Message "Adding SPNs 'WSMAN/$ComputerName' and 'WSMAN/$ComputerName.$DomainFQDN' to computer '$ComputerName'"
                setspn.exe -S "WSMAN/$ComputerName" "$ComputerName"
                setspn.exe -S "WSMAN/$ComputerName.$DomainFQDN" "$ComputerName"
            }
            GetScript = { }
            TestScript = {
                $ComputerName = $using:ComputerName
                $SamAccountName = "$ComputerName$"
                if ((Get-ADComputer -Filter {(SamAccountName -eq $SamAccountName)} -Property serviceprincipalname | Select-Object serviceprincipalname | Where-Object {$_.ServicePrincipalName -like "WSMAN/$ComputerName"}) -ne $null) {
                    return $true
                }
                else {
                    return $false
                }
            }
            DependsOn = "[PendingReboot]RebootOnSignalFromJoinDomain"
        }

        Script WaitForSPFarmReadyToJoin
        {
            SetScript = {
                $uri = "http://$($using:SharePointSitesAuthority)/sites/team"
                $SleepTime = 30
                $CurrentStatusCode = 0
                $ExpectedStatusCode = 200
                do {
                    try {
                        Write-Verbose -Verbose -Message "Trying to connect to $uri..."
                        $Response = Invoke-WebRequest -Uri $uri -UseDefaultCredentials -TimeoutSec 10 -ErrorAction Stop -UseBasicParsing
                        $CurrentStatusCode = $Response.StatusCode
                    }
                    catch [System.Net.WebException] {
                        if ($null -ne $_.Exception.Response) {
                            $CurrentStatusCode = $_.Exception.Response.StatusCode.value__
                        }
                    }
                    catch {
                        Write-Verbose -Verbose -Message "Request failed with an unexpected exception: $($_.Exception)"
                    }
                    if ($CurrentStatusCode -ne $ExpectedStatusCode) {
                        Write-Verbose -Verbose -Message "Connection to $uri returned status code $CurrentStatusCode while $ExpectedStatusCode is expected, retrying in $SleepTime secs..."
                        Start-Sleep -Seconds $SleepTime
                    }
                    else {
                        Write-Verbose -Verbose -Message "Connection to $uri returned expected status code $CurrentStatusCode, exiting..."
                    }
                } while ($CurrentStatusCode -ne $ExpectedStatusCode)
            }
            GetScript = { return @{ "Result" = "false" } }
            TestScript = { return $false }
            PsDscRunAsCredential = $DomainAdminCredsQualified
            DependsOn = "[Script]CreateWSManSPNsIfNeeded"
        }

        Group AddSPSetupAccountToAdminGroup
        {
            GroupName = "Administrators"
            Ensure = "Present"
            MembersToInclude = @("$($SPSetupCredsQualified.UserName)")
            Credential = $DomainAdminCredsQualified
            PsDscRunAsCredential = $DomainAdminCredsQualified
            DependsOn = "[Script]WaitForSPFarmReadyToJoin"
        }

        SPFarm JoinSPFarm
        {
            DatabaseServer = $SQLAlias
            FarmConfigDatabaseName = $SPDBPrefix + "Config"
            Passphrase = $SPPassphraseCreds
            FarmAccount = $SPFarmCredsQualified
            PsDscRunAsCredential = $SPSetupCredsQualified
            AdminContentDatabaseName = $SPDBPrefix + "AdminContent"
            RunCentralAdmin = $false
            IsSingleInstance = "Yes"
            ServerRole = "WebFrontEnd"
            SkipRegisterAsDistributedCacheHost = $true
            Ensure = "Present"
            DependsOn = "[Group]AddSPSetupAccountToAdminGroup"
        }

        DnsRecordCname UpdateDNSAliasSPSites
        {
            Name = $SharePointSitesAuthority
            ZoneName = $DomainFQDN
            DnsServer = $DCServerName
            HostNameAlias = "$ComputerName.$DomainFQDN"
            Ensure = "Present"
            PsDscRunAsCredential = $DomainAdminCredsQualified
            DependsOn = "[SPFarm]JoinSPFarm"
        }

        DnsRecordCname UpdateDNSAliasOhMy
        {
            Name = $MySiteHostAlias
            ZoneName = $DomainFQDN
            DnsServer = $DCServerName
            HostNameAlias = "$ComputerName.$DomainFQDN"
            Ensure = "Present"
            PsDscRunAsCredential = $DomainAdminCredsQualified
            DependsOn = "[SPFarm]JoinSPFarm"
        }

        DnsRecordCname UpdateDNSAliasHNSC1
        {
            Name = $HNSC1Alias
            ZoneName = $DomainFQDN
            DnsServer = $DCServerName
            HostNameAlias = "$ComputerName.$DomainFQDN"
            Ensure = "Present"
            PsDscRunAsCredential = $DomainAdminCredsQualified
            DependsOn = "[SPFarm]JoinSPFarm"
        }

        CertReq SPSSiteCert
        {
            CARootName = "$DomainNetbiosName-$DCServerName-CA"
            CAServerFQDN = "$DCServerName.$DomainFQDN"
            Subject = "$SharePointSitesAuthority.$DomainFQDN"
            FriendlyName = "$SharePointSitesAuthority.$DomainFQDN"
            SubjectAltName = "dns=*.$DomainFQDN&dns=*.$AppDomainIntranetFQDN"
            KeyLength = '2048'
            Exportable = $true
            ProviderName = '"Microsoft RSA SChannel Cryptographic Provider"'
            OID = '1.3.6.1.5.5.7.3.1'
            KeyUsage = '0xa0'
            CertificateTemplate = 'WebServer'
            AutoRenew = $true
            Credential = $DomainAdminCredsQualified
            DependsOn = "[SPFarm]JoinSPFarm"
        }

        Website SetHTTPSCertificate
        {
            Name = "SharePoint - 443"
            BindingInfo = DSC_WebBindingInformation
            {
                Protocol = "HTTPS"
                Port = 443
                CertificateStoreName = "My"
                CertificateSubject = "$SharePointSitesAuthority.$DomainFQDN"
            }
            Ensure = "Present"
            PsDscRunAsCredential = $DomainAdminCredsQualified
            DependsOn = "[CertReq]SPSSiteCert", "[SPFarm]JoinSPFarm"
        }

        Script DscStatus_Finished
        {
            SetScript = {
                "$(Get-Date -Format u)`t$($using:ComputerName)`tDSC Configuration finished." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript = { }
            TestScript = { return $false }
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