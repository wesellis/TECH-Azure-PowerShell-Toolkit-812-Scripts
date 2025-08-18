<#
.SYNOPSIS
    Configurespse

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
    We Enhanced Configurespse

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


configuration ConfigureSPVM
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)] [String]$WEDNSServerIP,
        [Parameter(Mandatory)] [String]$WEDomainFQDN,
        [Parameter(Mandatory)] [String]$WEDCServerName,
        [Parameter(Mandatory)] [String]$WESQLServerName,
        [Parameter(Mandatory)] [String]$WESQLAlias,
        [Parameter(Mandatory)] [String]$WESharePointVersion,
        [Parameter(Mandatory)] [String]$WESharePointSitesAuthority,
        [Parameter(Mandatory)] [String]$WESharePointCentralAdminPort,
        [Parameter(Mandatory)] [Boolean]$WEEnableAnalysis,
        [Parameter(Mandatory)] [System.Object[]] $WESharePointBits,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WEDomainAdminCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPSetupCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPFarmCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPSvcCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPAppPoolCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPADDirSyncCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPPassphraseCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPSuperUserCreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WESPSuperReaderCreds
    )

    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 10.0.0 # Custom
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 9.0.0
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion 6.6.2
    Import-DscResource -ModuleName xCredSSP -ModuleVersion 1.4.0
    Import-DscResource -ModuleName WebAdministrationDsc -ModuleVersion 4.2.1
    Import-DscResource -ModuleName SharePointDsc -ModuleVersion 5.6.1 # custom
    Import-DscResource -ModuleName DnsServerDsc -ModuleVersion 3.0.0
    Import-DscResource -ModuleName CertificateDsc -ModuleVersion 6.0.0
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 17.0.0
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.6.0.0    # With custom changes to implement retry on package downloads
    Import-DscResource -ModuleName StorageDsc -ModuleVersion 6.0.1
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 9.2.1
    
    # Init
    [String] $WEInterfaceAlias = (Get-NetAdapter -ErrorAction Stop | Where-Object InterfaceDescription -Like " Microsoft Hyper-V Network Adapter*" | Select-Object -First 1).Name
    [String] $WEComputerName = Get-Content -ErrorAction Stop env:computername
    [String] $WEDomainNetbiosName = (Get-NetBIOSName -DomainFQDN $WEDomainFQDN)
    [String] $WEDomainLDAPPath = " DC=$($WEDomainFQDN.Split(" ." )[0]),DC=$($WEDomainFQDN.Split(" ." )[1])"
    [String] $WEAdditionalUsersPath = " OU=AdditionalUsers,DC={0},DC={1}" -f $WEDomainFQDN.Split('.')[0], $WEDomainFQDN.Split('.')[1]

    # Format credentials to be qualified by domain name: " domain\username"
    [System.Management.Automation.PSCredential] $WEDomainAdminCredsQualified = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" $WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)" , $WEDomainAdminCreds.Password)
    [System.Management.Automation.PSCredential] $WESPSetupCredsQualified = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" $WEDomainNetbiosName\$($WESPSetupCreds.UserName)" , $WESPSetupCreds.Password)
    [System.Management.Automation.PSCredential] $WESPFarmCredsQualified = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" $WEDomainNetbiosName\$($WESPFarmCreds.UserName)" , $WESPFarmCreds.Password)
    [System.Management.Automation.PSCredential] $WESPSvcCredsQualified = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" $WEDomainNetbiosName\$($WESPSvcCreds.UserName)" , $WESPSvcCreds.Password)
    [System.Management.Automation.PSCredential] $WESPAppPoolCredsQualified = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" $WEDomainNetbiosName\$($WESPAppPoolCreds.UserName)" , $WESPAppPoolCreds.Password)
    [System.Management.Automation.PSCredential] $WESPADDirSyncCredsQualified = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" $WEDomainNetbiosName\$($WESPADDirSyncCreds.UserName)" , $WESPADDirSyncCreds.Password)
    
    # Setup settings
    [String] $WESetupPath = " C:\DSC Data"
    [String] $WEDCSetupPath = " \\$WEDCServerName\C$\DSC Data"
    [String] $WEDscStatusFilePath = " $WESetupPath\dsc-status-$WEComputerName.log"
    [String] $WESharePointBuildLabel = $WESharePointVersion.Split(" -" )[1]
    [String] $WESharePointBitsPath = Join-Path -Path $WESetupPath -ChildPath " Binaries" #[environment]::GetEnvironmentVariable(" temp" ," machine" )
    [String] $WESharePointIsoFullPath = Join-Path -Path $WESharePointBitsPath -ChildPath " OfficeServer.iso"
    [String] $WESharePointIsoDriveLetter = " S"
    [String] $WEAdfsDnsEntryName = " adfs"
    [String] $WELdapcpSolutionName = " LDAPCPSE"
    [String] $WELdapcpSolutionId = " ff36c8cf-e510-42fc-8ba3-18af3c316aec"
    [String] $WELdapcpReleaseId = " latest"
    [String] $WELDAPCPFileFullPath = Join-Path -Path $WESetupPath -ChildPath " Binaries\$WELdapcpSolutionName.wsp"

    # SharePoint settings
    [String] $WESPDBPrefix = " SPDSC_"
    [String] $WEServiceAppPoolName = " SharePoint Service Applications"
    [String] $WEUpaServiceName = " User Profile Service Application"
    [String] $WEAppDomainFQDN = " {0}{1}.{2}" -f $WEDomainFQDN.Split('.')[0], " Apps" , $WEDomainFQDN.Split('.')[1]
    [String] $WEAppDomainIntranetFQDN = " {0}{1}.{2}" -f $WEDomainFQDN.Split('.')[0], " Apps-Intranet" , $WEDomainFQDN.Split('.')[1]
    [String] $WEMySiteHostAlias = " OhMy"
    [String] $WEHNSC1Alias = " HNSC1"
    [String] $WEAddinsSiteDNSAlias = " addins"
    [String] $WEAddinsSiteName = " Provider-hosted addins"
    [String] $WETrustedIdChar = " e"
    [String] $WESPTeamSiteTemplate = " STS#3"
    [String];  $WEAdfsOidcIdentifier = " fae5bd07-be63-4a64-a28c-7931a4ebf62b"
    
    Node localhost
    {
        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        Script DscStatus_Start {
            SetScript  =
            {
               ;  $destinationFolder = $using:SetupPath
                if (!(Test-Path $destinationFolder -PathType Container)) {
                    New-Item -ItemType Directory -Force -Path $destinationFolder
                }
                " $(Get-Date -Format u)`t$($using:ComputerName)`tDSC Configuration starting..." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript  = { } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        }

        #**********************************************************
        # Initialization of VM - Do as much work as possible before waiting on AD domain to be available
        #**********************************************************
        WindowsFeature AddADTools {
            Name = " RSAT-AD-Tools" ; Ensure = " Present" ; 
        }
        WindowsFeature AddDnsTools {
            Name = " RSAT-DNS-Server" ; Ensure = " Present" ; 
        }
        WindowsFeature AddADLDS {
            Name = " RSAT-ADLDS" ; Ensure = " Present" ; 
        }
        WindowsFeature AddADCSManagementTools {
            Name = " RSAT-ADCS-Mgmt" ; Ensure = " Present" ; 
        }
        DnsServerAddress SetDNS {
            Address = $WEDNSServerIP; InterfaceAlias = $WEInterfaceAlias; AddressFamily = 'IPv4' 
        }
        

        # xCredSSP is required forSharePointDsc resources SPUserProfileServiceApp and SPDistributedCacheService
        xCredSSP CredSSPServer {
            Ensure = " Present" ; Role = " Server" ; DependsOn = " [DnsServerAddress]SetDNS" 
        }
        xCredSSP CredSSPClient {
            Ensure = " Present" ; Role = " Client" ; DelegateComputers = " *.$WEDomainFQDN" , " localhost" ; DependsOn = " [xCredSSP]CredSSPServer" 
        }

        # Allow NTLM on HTTPS sites when site host name is different than the machine name - https://docs.microsoft.com/en-US/troubleshoot/windows-server/networking/accessing-server-locally-with-fqdn-cname-alias-denied
        Registry DisableLoopBackCheck {
            Key = " HKLM:\System\CurrentControlSet\Control\Lsa" ; ValueName = " DisableLoopbackCheck" ; ValueData = " 1" ; ValueType = " Dword" ; Ensure = " Present" 
        }

        # Enable TLS 1.2 - https://learn.microsoft.com/en-us/azure/active-directory/app-proxy/application-proxy-add-on-premises-application#tls-requirements
        # This allows xRemoteFile to download releases from GitHub: https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/405
        Registry EnableTLS12RegKey1 {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'; ValueName = 'DisabledByDefault'; ValueType = 'Dword'; ValueData = '0'; Ensure = 'Present' 
        }
        Registry EnableTLS12RegKey2 {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'; ValueName = 'Enabled'; ValueType = 'Dword'; ValueData = '1'; Ensure = 'Present' 
        }
        Registry EnableTLS12RegKey3 {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'; ValueName = 'DisabledByDefault'; ValueType = 'Dword'; ValueData = '0'; Ensure = 'Present' 
        }
        Registry EnableTLS12RegKey4 {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'; ValueName = 'Enabled'; ValueType = 'Dword'; ValueData = '1'; Ensure = 'Present' 
        }

        # Enable strong crypto by default for .NET Framework 4 applications - https://docs.microsoft.com/en-us/dotnet/framework/network-programming/tls#configuring-security-via-the-windows-registry
        Registry SchUseStrongCrypto {
            Key = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'; ValueName = 'SchUseStrongCrypto'; ValueType = 'Dword'; ValueData = '1'; Ensure = 'Present' 
        }
        Registry SchUseStrongCrypto32 {
            Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'; ValueName = 'SchUseStrongCrypto'; ValueType = 'Dword'; ValueData = '1'; Ensure = 'Present' 
        }
        Registry SystemDefaultTlsVersions {
            Key = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'; ValueName = 'SystemDefaultTlsVersions'; ValueType = 'Dword'; ValueData = '1'; Ensure = 'Present' 
        }
        Registry SystemDefaultTlsVersions32 {
            Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'; ValueName = 'SystemDefaultTlsVersions'; ValueType = 'Dword'; ValueData = '1'; Ensure = 'Present' 
        }

        Registry DisableIESecurityRegKey1 {
            Key = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'; ValueName = 'IsInstalled'; ValueType = 'Dword'; ValueData = '0'; Force = $true ; Ensure = 'Present' 
        }
        Registry DisableIESecurityRegKey2 {
            Key = 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Main'; ValueName = 'DisableFirstRunCustomize'; ValueType = 'Dword'; ValueData = '1'; Force = $true ; Ensure = 'Present' 
        }
        Registry DisableIESecurityRegKey3 {
            Key = 'HKLM:\Software\Policies\Microsoft\Internet Explorer\TabbedBrowsing'; ValueName = 'NewTabPageShow'; ValueType = 'Dword'; ValueData = '0'; Force = $true ; Ensure = 'Present' 
        }

        # From https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=powershell :
        # Starting in Windows 10, version 1607, MAX_PATH limitations have been removed from common Win32 file and directory functions. However, you must opt-in to the new behavior.
        Registry SetLongPathsEnabled {
            Key = " HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" ; ValueName = " LongPathsEnabled" ; ValueType = " DWORD" ; ValueData = " 1" ; Force = $true; Ensure = " Present" 
        }
        
        Registry ShowWindowsExplorerRibbon {
            Key = " HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" ; ValueName = " ExplorerRibbonStartsMinimized" ; ValueType = " DWORD" ; ValueData = " 4" ; Force = $true; Ensure = " Present" 
        }

        # # Set registry keys to allow OneDrive NGSC to connect to SPS using OIDC - part 1 (machine-wide)
        # Registry OneDriveOIDC_PrioritizeOIDCOverLegacyAuthN {
        #     Key = " HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" ; ValueName = " SharePointOnPremOIDC" ; ValueType = " DWORD" ; ValueData = " 1" ; Ensure = " Present" 
        # }
        # Registry OneDriveOIDC_PrioritizeSPSOverSPO {
        #     Key = " HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" ; ValueName = " SharePointOnPremPrioritization" ; ValueType = " DWORD" ; ValueData = " 1" ; Ensure = " Present" 
        # }
        # Registry OneDriveOIDC_SPSUrl {
        #     Key = " HKLM:\Software\Policies\Microsoft\OneDrive" ; ValueName = " SharePointOnPremFrontDoorUrl" ; ValueType = " String" ; ValueData = " https://$WESharePointSitesAuthority.$WEDomainFQDN" ; Ensure = " Present" 
        # }
        
        SqlAlias AddSqlAlias {
            Ensure = " Present" ; Name = $WESQLAlias; ServerName = $WESQLServerName; Protocol = " TCP" ; TcpPort = 1433 
        }
        
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

        # Create the rules in the firewall required for the distributed cache - https://learn.microsoft.com/en-us/sharepoint/administration/plan-for-feeds-and-the-distributed-cache-service#firewall
        Script CreateFirewallRulesForDistributedCache {
            TestScript = {
                # Test if firewall rules already exist
                $icmpRuleName = " File and Printer Sharing (Echo Request - ICMPv4-In)"
                $icmpFirewallRule = Get-NetFirewallRule -DisplayName $icmpRuleName -ErrorAction SilentlyContinue
                $spRuleName = " SharePoint Distributed Cache"
                $firewallRule = Get-NetFirewallRule -DisplayName $spRuleName -ErrorAction SilentlyContinue
                if ($null -eq $icmpFirewallRule -or $null -eq $firewallRule) {
                    return $false   # Run SetScript
                }
                else {
                    return $true    # Rules already set
                }
            }
            SetScript  = {
                # $icmpRuleName = " File and Printer Sharing (Echo Request - ICMPv4-In)"
                # $icmpFirewallRule = Get-NetFirewallRule -DisplayName $icmpRuleName -ErrorAction SilentlyContinue
                # if ($null -eq $icmpFirewallRule) {
                #     New-NetFirewallRule -Name Allow_Ping -DisplayName $icmpRuleName `
                #         -Description " Allow ICMPv4 ping" `
                #         -Protocol ICMPv4 `
                #         -IcmpType 8 `
                #         -Enabled True `
                #         -Profile Any `
                #         -Action Allow
                # }
                # Enable-NetFirewallRule -DisplayName $icmpRuleName
                Enable-NetFirewallRule -displayName " File and Printer Sharing (Echo Request - ICMPv4-In)"

                $spRuleName = " SharePoint Distributed Cache"
                $firewallRule = Get-NetFirewallRule -DisplayName $spRuleName -ErrorAction SilentlyContinue
                if ($null -eq $firewallRule) {
                    New-NetFirewallRule -Name " SPDistCache" `
                        -DisplayName $spRuleName `
                        -Protocol TCP `
                        -LocalPort 22233-22236 `
                        -Group " SharePoint"
                }                
                Enable-NetFirewallRule -DisplayName $spRuleName
            }
            GetScript  = { }
        }

        xRemoteFile DownloadLDAPCP {
            DestinationPath = $WELDAPCPFileFullPath
            Uri             = Get-LatestGitHubRelease -Repo " Yvand/LDAPCP" -Artifact " *.wsp" -ReleaseId $WELdapcpReleaseId
            MatchSource     = $false
        }

        #**********************************************************
        # Install applications using Chocolatey
        #**********************************************************
        Script DscStatus_InstallApps {
            SetScript  =
            {
                " $(Get-Date -Format u)`t$($using:ComputerName)`tInstall applications..." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript  = { } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        }

        cChocoInstaller InstallChoco {
            InstallDir = " C:\Chocolatey"
        }

        cChocoPackageInstaller InstallNotepadpp {
            Name      = " notepadplusplus.install"
            Ensure    = " Present"
            DependsOn = " [cChocoInstaller]InstallChoco"
        }

        cChocoPackageInstaller Install7zip {
            Name      = " 7zip.install"
            Ensure    = " Present"
            DependsOn = " [cChocoInstaller]InstallChoco"
        }

        cChocoPackageInstaller InstallVscode {
            # Install takes about 30 secs
            Name      = " vscode"
            Ensure    = " Present"
            DependsOn = " [cChocoInstaller]InstallChoco"
        }

        cChocoPackageInstaller InstallAzureDataStudio {
            # Install takes about 40 secs
            Name      = " azure-data-studio"
            Ensure    = " Present"
            DependsOn = " [cChocoInstaller]InstallChoco"
        }

        # if ($WEEnableAnalysis) {
        #     # This resource is only for analyzing dsc logs using a custom Python script
        #     cChocoPackageInstaller InstallPython
        #     {
        #         Name                 = " python"
        #         Ensure               = " Present"
        #         DependsOn            = " [cChocoInstaller]InstallChoco"
        #     }
        # }

        #**********************************************************
        # Download and install for SharePoint
        #**********************************************************
        Script DscStatus_DownloadSharePoint {
            SetScript  =
            {
                " $(Get-Date -Format u)`t$($using:ComputerName)`tDownload SharePoint bits and install it..." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript  = { } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        }

        xRemoteFile DownloadSharePoint {
            DestinationPath = $WESharePointIsoFullPath
            Uri             = ($WESharePointBits | Where-Object { $_.Label -eq " RTM" }).Packages[0].DownloadUrl
            ChecksumType    = ($WESharePointBits | Where-Object { $_.Label -eq " RTM" }).Packages[0].ChecksumType
            Checksum        = ($WESharePointBits | Where-Object { $_.Label -eq " RTM" }).Packages[0].Checksum
            MatchSource     = $false
        }
        
        MountImage MountSharePointImage {
            ImagePath   = $WESharePointIsoFullPath
            DriveLetter = $WESharePointIsoDriveLetter
            DependsOn   = " [xRemoteFile]DownloadSharePoint"
        }
          
        WaitForVolume WaitForSharePointImage {
            DriveLetter      = $WESharePointIsoDriveLetter
            RetryIntervalSec = 5
            RetryCount       = 10
            DependsOn        = " [MountImage]MountSharePointImage"
        }

        SPInstallPrereqs InstallPrerequisites {
            IsSingleInstance = " Yes"
            InstallerPath    = " $($WESharePointIsoDriveLetter):\Prerequisiteinstaller.exe"
            OnlineMode       = $true
            DependsOn        = " [WaitForVolume]WaitForSharePointImage"
        }

        SPInstall InstallBinaries {
            IsSingleInstance = " Yes"
            BinaryDir        = " $($WESharePointIsoDriveLetter):\"
            ProductKey       = " VW2FM-FN9FT-H22J4-WV9GT-H8VKF"
            DependsOn        = " [SPInstallPrereqs]InstallPrerequisites"
        }

        if ($WESharePointBuildLabel -ne " RTM" ) {
            foreach ($package in ($WESharePointBits | Where-Object { $_.Label -eq $WESharePointBuildLabel }).Packages) {
                $packageUrl = [uri] $package.DownloadUrl
                $packageFilename = $packageUrl.Segments[$packageUrl.Segments.Count - 1]
                $packageFilePath = Join-Path -Path $WESharePointBitsPath -ChildPath $packageFilename
                
                xRemoteFile " DownloadSharePointUpdate_$($WESharePointBuildLabel)_$packageFilename" {
                    DestinationPath = $packageFilePath
                    Uri             = $packageUrl
                    ChecksumType    = if ($null -ne $package.ChecksumType) { $package.ChecksumType } else { " None" }
                    Checksum        = if ($null -ne $package.Checksum) { $package.Checksum } else { $null }
                    MatchSource     = $false
                }

                Script " InstallSharePointUpdate_$($WESharePointBuildLabel)_$packageFilename" {
                    SetScript  = {
                        $WESharePointBuildLabel = $using:SharePointBuildLabel
                        $packageFilePath = $using:packageFilePath
                        $packageFile = Get-ChildItem -Path $packageFilePath
                        
                        $exitRebootCodes = @(3010, 17022)
                        $needReboot = $false
                        Write-Verbose -Verbose -Message " Starting installation of SharePoint update '$WESharePointBuildLabel', file '$($packageFile.Name)'..."
                        Unblock-File -Path $packageFile -Confirm:$false
                       ;  $process = Start-Process $packageFile.FullName -ArgumentList '/passive /quiet /norestart' -PassThru -Wait
                        if ($exitRebootCodes.Contains($process.ExitCode)) {
                           ;  $needReboot = $true
                        }
                        Write-Verbose -Verbose -Message " Finished installation of SharePoint update '$($packageFile.Name)'. Exit code: $($process.ExitCode); needReboot: $needReboot"
                        New-Item -Path " HKLM:\SOFTWARE\DscScriptExecution\flag_spupdate_$($WESharePointBuildLabel)_$($packageFile.Name)" -Force
                        Write-Verbose -Verbose -Message " Finished installation of SharePoint build '$WESharePointBuildLabel'. needReboot: $needReboot"

                        if ($true -eq $needReboot) {
                            $script:DSCMachineStatus = 1
                        }
                    }
                    TestScript = {
                        $WESharePointBuildLabel = $using:SharePointBuildLabel
                       ;  $packageFilePath = $using:packageFilePath
                       ;  $packageFile = Get-ChildItem -Path $packageFilePath
                        return (Test-Path " HKLM:\SOFTWARE\DscScriptExecution\flag_spupdate_$($WESharePointBuildLabel)_$($packageFile.Name)" )
                    }
                    GetScript  = { return @{ " Result" = " false" } } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                    DependsOn  = " [SPInstall]InstallBinaries"
                }

                # SPProductUpdate " InstallSharePointUpdate_$($WESharePointBuildLabel)_$packageFilename"
                # {
                #     SetupFile            = $packageFilePath
                #     Ensure               = " Present"
                #     DependsOn            = " [SPInstall]InstallBinaries"
                #     # PsDscRunAsCredential = $WESetupAccount
                # }

                PendingReboot " RebootOnSignalFromInstallSharePointUpdate_$($WESharePointBuildLabel)_$packageFilename" {
                    Name             = " RebootOnSignalFromInstallSharePointUpdate_$($WESharePointBuildLabel)_$packageFilename"
                    SkipCcmClientSDK = $true
                    DependsOn        = " [Script]InstallSharePointUpdate_$($WESharePointBuildLabel)_$packageFilename"
                }
            }
        }

        # IIS cleanup cannot be executed earlier in SharePoint SE: It uses a base image of Windows Server without IIS (installed by SPInstallPrereqs)
        WebAppPool RemoveDotNet2Pool {
            Name = " .NET v2.0" ; Ensure = " Absent" ; 
        }
        WebAppPool RemoveDotNet2ClassicPool {
            Name = " .NET v2.0 Classic" ; Ensure = " Absent" ; 
        }
        WebAppPool RemoveDotNet45Pool {
            Name = " .NET v4.5" ; Ensure = " Absent" ; 
        }
        WebAppPool RemoveDotNet45ClassicPool {
            Name = " .NET v4.5 Classic" ; Ensure = " Absent" ; 
        }
        WebAppPool RemoveClassicDotNetPool {
            Name = " Classic .NET AppPool" ; Ensure = " Absent" ; 
        }
        WebAppPool RemoveDefaultAppPool {
            Name = " DefaultAppPool" ; Ensure = " Absent" ; 
        }
        WebSite    RemoveDefaultWebSite {
            Name = " Default Web Site" ; Ensure = " Absent" ; PhysicalPath = " C:\inetpub\wwwroot" ; 
        }

        Script CreateSPLOGSFileShare {
            SetScript  = 
            { 
                $foldername = " C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\LOGS"
                $shareName = " SPLOGS"
                # if (!(Get-CimInstance -ErrorAction Stop Win32_Share -Filter " name='$sharename'" )) {
                $shares = [WMICLASS]" WIN32_Share"
                if ($shares.Create($foldername, $sharename, 0).ReturnValue -ne 0) {
                    Write-Verbose -Verbose -Message " Failed to create file share '$sharename' for folder '$foldername'"
                }
                else {
                    Write-Verbose -Verbose -Message " Created file share '$sharename' for folder '$foldername'"
                }
                # }
            }
            GetScript  = { }
            TestScript = 
            {
                $shareName = " SPLOGS"
                if (!(Get-CimInstance -ErrorAction Stop Win32_Share -Filter " name='$sharename'" )) {
                    return $false
                }
                else {
                    return $true
                }
            }
        }

        #**********************************************************
        # Join AD forest
        #**********************************************************
        
        Script DscStatus_WaitForDCReady {
            SetScript  =
            {
                " $(Get-Date -Format u)`t$($using:ComputerName)`tWait for AD DC to be ready..." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript  = { } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        }
        
        # DNS record for ADFS is created only after the ADFS farm was created and DC restarted (required by ADFS setup)
        # This turns out to be a very reliable way to ensure that VM joins AD only when the DC is guaranteed to be ready
        # This totally eliminates the random errors that occured in WaitForADDomain with the previous logic (and no more need of WaitForADDomain)
        Script WaitForADFSFarmReady {
            SetScript  =
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
            GetScript  = { return @{ " Result" = " false" } } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { try { [Net.DNS]::GetHostEntry(" $($using:AdfsDnsEntryName).$($using:DomainFQDN)" ); return $true } catch { return $false } }
            DependsOn  = " [DnsServerAddress]SetDNS"
        }

        # # If WaitForADDomain does not find the domain whtin " WaitTimeout" secs, it will signal a restart to DSC engine " RestartCount" times
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

        Computer JoinDomain {
            Name       = $WEComputerName
            DomainName = $WEDomainFQDN
            Credential = $WEDomainAdminCredsQualified
            DependsOn  = " [Script]WaitForADFSFarmReady"
        }

        PendingReboot RebootOnSignalFromJoinDomain {
            Name             = " RebootOnSignalFromJoinDomain"
            SkipCcmClientSDK = $true
            DependsOn        = " [Computer]JoinDomain"
        }

        Registry ShowFileExtensions {
            Key = " HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" ; ValueName = " HideFileExt" ; ValueType = " DWORD" ; ValueData = " 0" ; Force = $true;
            PsDscRunAsCredential = $WEDomainAdminCredsQualified; Ensure = " Present"
        }

        # # Set registry keys to allow OneDrive NGSC to connect to SPS using OIDC - part 2 (user-specific settings)
        # Registry OneDriveOIDC_EnableOIDCForSPS {
        #     Key = " HKCU:\Software\Microsoft\OneDrive\PreSignInRampOverrides" ; ValueName = " 2086" ; ValueType = " DWORD" ; ValueData = " 1"
        #     PsDscRunAsCredential = $WEDomainAdminCredsQualified; Ensure = " Present" 
        # }
        # Registry OneDriveOIDC_EnableOneAuthorSPS {
        #     Key = " HKCU:\Software\Microsoft\OneDrive\PreSignInRampOverrides" ; ValueName = " 2042" ; ValueType = " DWORD" ; ValueData = " 1"
        #     PsDscRunAsCredential = $WEDomainAdminCredsQualified; Ensure = " Present" 
        # }
        # Registry OneDriveOIDC_IniFileNamingForEmailAndUpn {
        #     Key = " HKCU:\Software\Microsoft\OneDrive\PreSignInSettingsOverrides" ; ValueName = " 204" ; ValueType = " String" ; ValueData = " -1835"
        #     PsDscRunAsCredential = $WEDomainAdminCredsQualified; Ensure = " Present" 
        # }

        # This script is still needed
        Script CreateWSManSPNsIfNeeded {
            SetScript  =
            {
                # A few times, deployment failed because of this error:
                # " The WinRM client cannot process the request. A computer policy does not allow the delegation of the user credentials to the target computer because the computer is not trusted."
                # The root cause was that SPNs WSMAN/SP and WSMAN/sp.contoso.local were missing in computer account contoso\SP
                # Those SPNs are created by WSMan when it (re)starts
                # Restarting service causes an error, so creates SPNs manually instead
                # Restart-Service winrm

                # Create SPNs WSMAN/SP and WSMAN/sp.contoso.local
                $domainFQDN = $using:DomainFQDN
                $computerName = $using:ComputerName
                Write-Verbose -Verbose -Message " Adding SPNs 'WSMAN/$computerName' and 'WSMAN/$computerName.$domainFQDN' to computer '$computerName'"
                setspn.exe -S " WSMAN/$computerName" " $computerName"
                setspn.exe -S " WSMAN/$computerName.$domainFQDN" " $computerName"
            }
            GetScript  = { }
            # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
            TestScript = 
            {
                $computerName = $using:ComputerName
                $samAccountName = " $computerName$"
                if ((Get-ADComputer -Filter { (SamAccountName -eq $samAccountName) } -Property serviceprincipalname | Select-Object serviceprincipalname | Where-Object { $_.ServicePrincipalName -like " WSMAN/$computerName" }) -ne $null) {
                    # SPN is present
                    return $true
                }
                else {
                    # SPN is missing and must be created
                    return $false
                }
            }
            DependsOn  = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        #**********************************************************
        # Do SharePoint pre-reqs that require membership in AD domain
        #**********************************************************
        # Create DNS entries used by SharePoint
        DnsRecordCname AddTrustedSiteDNS {
            Name                 = $WESharePointSitesAuthority
            ZoneName             = $WEDomainFQDN
            DnsServer            = $WEDCServerName
            HostNameAlias        = " $WEComputerName.$WEDomainFQDN"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        DnsRecordCname AddMySiteHostDNS {
            Name                 = $WEMySiteHostAlias
            ZoneName             = $WEDomainFQDN
            DnsServer            = $WEDCServerName
            HostNameAlias        = " $WEComputerName.$WEDomainFQDN"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        DnsRecordCname AddHNSC1DNS {
            Name                 = $WEHNSC1Alias
            ZoneName             = $WEDomainFQDN
            DnsServer            = $WEDCServerName
            HostNameAlias        = " $WEComputerName.$WEDomainFQDN"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        DnsRecordCname AddAddinDNSWildcard {
            Name                 = " *"
            ZoneName             = $WEAppDomainFQDN
            HostNameAlias        = " $WEComputerName.$WEDomainFQDN"
            DnsServer            = " $WEDCServerName.$WEDomainFQDN"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        DnsRecordCname AddAddinDNSWildcardInIntranetZone {
            Name                 = " *"
            ZoneName             = $WEAppDomainIntranetFQDN
            HostNameAlias        = " $WEComputerName.$WEDomainFQDN"
            DnsServer            = " $WEDCServerName.$WEDomainFQDN"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        DnsRecordCname ProviderHostedAddinsAlias {
            Name                 = $WEAddinsSiteDNSAlias
            ZoneName             = $WEDomainFQDN
            HostNameAlias        = " $WEComputerName.$WEDomainFQDN"
            DnsServer            = " $WEDCServerName.$WEDomainFQDN"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        #**********************************************************
        # Provision required accounts for SharePoint
        #**********************************************************
        ADUser CreateSPSetupAccount {
            # Both SQL and SharePoint DSCs run this SPSetupAccount AD account creation
            DomainName           = $WEDomainFQDN
            UserName             = $WESPSetupCreds.UserName
            UserPrincipalName    = " $($WESPSetupCreds.UserName)@$WEDomainFQDN"
            Password             = $WESPSetupCreds
            PasswordNeverExpires = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        ADUser CreateSParmAccount {
            DomainName           = $WEDomainFQDN
            UserName             = $WESPFarmCreds.UserName
            UserPrincipalName    = " $($WESPFarmCreds.UserName)@$WEDomainFQDN"
            Password             = $WESPFarmCreds
            PasswordNeverExpires = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        Group AddSPSetupAccountToAdminGroup {
            GroupName            = " Administrators"
            Ensure               = " Present"
            MembersToInclude     = @(" $($WESPSetupCredsQualified.UserName)" )
            Credential           = $WEDomainAdminCredsQualified
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [ADUser]CreateSPSetupAccount"
        }

        ADUser CreateSPSvcAccount {
            DomainName           = $WEDomainFQDN
            UserName             = $WESPSvcCreds.UserName
            UserPrincipalName    = " $($WESPSvcCreds.UserName)@$WEDomainFQDN"
            Password             = $WESPSvcCreds
            PasswordNeverExpires = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        ADUser CreateSPAppPoolAccount {
            DomainName            = $WEDomainFQDN
            UserName              = $WESPAppPoolCreds.UserName
            UserPrincipalName     = " $($WESPAppPoolCreds.UserName)@$WEDomainFQDN"
            Password              = $WESPAppPoolCreds
            PasswordNeverExpires  = $true
            Ensure                = " Present"
            ServicePrincipalNames = @(" HTTP/$WESharePointSitesAuthority.$($WEDomainFQDN)" , " HTTP/$WEMySiteHostAlias.$($WEDomainFQDN)" , " HTTP/$WEHNSC1Alias.$($WEDomainFQDN)" , " HTTP/$WESharePointSitesAuthority" , " HTTP/$WEMySiteHostAlias" , " HTTP/$WEHNSC1Alias" )
            PsDscRunAsCredential  = $WEDomainAdminCredsQualified
            DependsOn             = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        ADUser CreateSPSuperUserAccount {
            DomainName           = $WEDomainFQDN
            UserName             = $WESPSuperUserCreds.UserName
            UserPrincipalName    = " $($WESPSuperUserCreds.UserName)@$WEDomainFQDN"
            Password             = $WESPSuperUserCreds
            PasswordNeverExpires = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        ADUser CreateSPSuperReaderAccount {
            DomainName           = $WEDomainFQDN
            UserName             = $WESPSuperReaderCreds.UserName
            UserPrincipalName    = " $($WESPSuperReaderCreds.UserName)@$WEDomainFQDN"
            Password             = $WESPSuperReaderCreds
            PasswordNeverExpires = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        ADUser CreateSPADDirSyncAccount {
            DomainName           = $WEDomainFQDN
            UserName             = $WESPADDirSyncCreds.UserName
            UserPrincipalName    = " $($WESPADDirSyncCreds.UserName)@$WEDomainFQDN"
            Password             = $WESPADDirSyncCreds
            PasswordNeverExpires = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        ADObjectPermissionEntry GrantReplicatingDirectoryChanges {
            Ensure                             = 'Present'
            Path                               = $WEDomainLDAPPath
            IdentityReference                  = $WESPADDirSyncCreds.UserName
            ActiveDirectoryRights              = 'ExtendedRight'
            AccessControlType                  = 'Allow'
            ObjectType                         = " 1131f6aa-9c07-11d1-f79f-00c04fc2dcd2" # Replicate Directory Changes Permission
            ActiveDirectorySecurityInheritance = 'All'
            InheritedObjectType                = '00000000-0000-0000-0000-000000000000'
            PsDscRunAsCredential               = $WEDomainAdminCredsQualified
            DependsOn                          = " [ADUser]CreateSPADDirSyncAccount"
        }
        
        # Fiddler must be installed as $WEDomainAdminCredsQualified because it's a per-user installation
        cChocoPackageInstaller InstallFiddler {
            Name                 = " fiddler"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [cChocoInstaller]InstallChoco" , " [PendingReboot]RebootOnSignalFromJoinDomain"
        }

        # Install ULSViewer as $WEDomainAdminCredsQualified to ensure that the shortcut is visible on the desktop
        cChocoPackageInstaller InstallUlsViewer {
            Name                 = " ulsviewer"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [cChocoInstaller]InstallChoco"
        }

        Script DscStatus_WaitForSQL {
            SetScript  =
            {
                " $(Get-Date -Format u)`t$($using:ComputerName)`tWait for SQL Server to be ready..." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript  = { } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        }

        Script WaitForSQL {
            SetScript            =
            {
                $retrySleep = 30
                $server = $using:SQLAlias
                $db = " master"
               ;  $retry = $true
                while ($retry) {
                   ;  $sqlConnection = New-Object -ErrorAction Stop System.Data.SqlClient.SqlConnection " Data Source=$server;Initial Catalog=$db;Integrated Security=True;Enlist=False;Connect Timeout=3"
                    try {
                        $sqlConnection.Open()
                        Write-Verbose -Verbose -Message " Connection to SQL Server $server succeeded"
                        $sqlConnection.Close()
                        $retry = $false
                    }
                    catch {
                        Write-Verbose -Verbose -Message " SQL connection to $server failed, retry in $retrySleep secs..."
                        Start-Sleep -s $retrySleep
                    }
                }
            }
            GetScript            = { return @{ " Result" = " false" } } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript           = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SqlAlias]AddSqlAlias"
        }

        #**********************************************************
        # Create SharePoint farm
        #**********************************************************
        Script DscStatus_CreateSPFarm {
            SetScript  =
            {
                " $(Get-Date -Format u)`t$($using:ComputerName)`tCreate SharePoint farm..." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript  = { } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        }

        SPFarm CreateSPFarm {
            DatabaseServer                     = $WESQLAlias
            FarmConfigDatabaseName             = $WESPDBPrefix + " Config"
            Passphrase                         = $WESPPassphraseCreds
            FarmAccount                        = $WESPFarmCredsQualified
            PsDscRunAsCredential               = $WESPSetupCredsQualified
            AdminContentDatabaseName           = $WESPDBPrefix + " AdminContent"
            CentralAdministrationPort          = $WESharePointCentralAdminPort
            # If RunCentralAdmin is false and configdb does not exist, SPFarm checks during 30 mins if configdb got created and joins the farm
            RunCentralAdmin                    = $true
            IsSingleInstance                   = " Yes"
            SkipRegisterAsDistributedCacheHost = $false
            Ensure                             = " Present"
            DependsOn                          = " [Script]WaitForSQL" , " [Group]AddSPSetupAccountToAdminGroup" , " [ADUser]CreateSParmAccount" , " [ADUser]CreateSPSvcAccount" , " [ADUser]CreateSPAppPoolAccount" , " [ADUser]CreateSPSuperUserAccount" , " [ADUser]CreateSPSuperReaderAccount" , " [ADObjectPermissionEntry]GrantReplicatingDirectoryChanges" , " [Script]CreateWSManSPNsIfNeeded"
        }

        Script AddRequiredDatabasesPermissions {
            SetScript            =
            {
                # https://learn.microsoft.com/en-us/sharepoint/security-for-sharepoint-server/plan-for-least-privileged-administration
                # Required for slipstream installs with 2022-10 CU or greated
                foreach ($db in Get-SPDatabase) {
                    $db.GrantOwnerAccessToDatabaseAccount()
                }
            }
            GetScript            = { }
            TestScript           = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPFarm]CreateSPFarm"
        }

        Script RestartSPTimerAfterCreateSPFarm {
            SetScript            =
            {
                # Restarting both SPAdminV4 and SPTimerV4 services before deploying solution makes deployment a lot more reliable
                Restart-Service SPTimerV4, SPAdminV4
            }
            GetScript            = { }
            TestScript           = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPFarm]CreateSPFarm"
        }

        # Delay this operation significantly, so that DC has time to generate and copy the certificates
        File CopyCertificatesFromDC {
            Ensure          = " Present"
            Type            = " Directory"
            Recurse         = $true
            SourcePath      = " $WEDCSetupPath"
            DestinationPath = " $WESetupPath\Certificates"
            Credential      = $WEDomainAdminCredsQualified
            DependsOn       = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        SPTrustedRootAuthority TrustRootCA {
            Name                 = " $WEDomainFQDN root CA"
            CertificateFilePath  = " $WESetupPath\Certificates\ADFS Signing issuer.cer"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [File]CopyCertificatesFromDC"
        }

        SPFarmSolution InstallLdapcpSolution {
            LiteralPath          = $WELDAPCPFileFullPath
            Name                 = " $WELdapcpSolutionName.wsp"
            Deployed             = $true
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        Script InstallLdapcpFeatures {
            SetScript            = 
            {
                $solutionId = $using:LdapcpSolutionId
                Install-SPFeature -SolutionId $solutionId -AllExistingFeatures
            }
            GetScript            =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ " Result" = " false" }
            }
            TestScript           = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                $claimsProviderName = $using:LdapcpSolutionName
                if ($null -eq (Get-SPClaimProvider -Identity $claimsProviderName -ErrorAction SilentlyContinue)) {
                    return $false
                }
                else {
                    return $true
                }
            }
            DependsOn            = " [SPFarmSolution]InstallLdapcpSolution"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        SPManagedAccount CreateSPSvcManagedAccount {
            AccountName          = $WESPSvcCredsQualified.UserName
            Account              = $WESPSvcCredsQualified
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        SPManagedAccount CreateSPAppPoolManagedAccount {
            AccountName          = $WESPAppPoolCredsQualified.UserName
            Account              = $WESPAppPoolCredsQualified
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        SPStateServiceApp StateServiceApp {
            Name                 = " State Service Application"
            DatabaseName         = $WESPDBPrefix + " StateService"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        # Distributed Cache is now enabled directly by the SPFarm resource
        # SPDistributedCacheService EnableDistributedCache
        # {
        #     Name                 = " AppFabricCachingService"
        #     CacheSizeInMB        = 1000 # Default size is 819MB on a server with 16GB of RAM (5%)
        #     CreateFirewallRules  = $true
        #     ServiceAccount       = $WESPFarmCredsQualified.UserName
        #     PsDscRunAsCredential       = $WEDomainAdminCredsQualified
        #     Ensure               = " Present"
        #     DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        # }

        #**********************************************************
        # Service instances are started at the beginning of the deployment to give some time between this and creation of service applications
        # This makes deployment a lot more reliable and avoids errors related to concurrency update of persisted objects, or service instance not found...
        #**********************************************************
        SPServiceInstance UPAServiceInstance {
            Name                 = " User Profile Service"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        SPServiceInstance StartSubscriptionSettingsServiceInstance {
            Name                 = " Microsoft SharePoint Foundation Subscription Settings Service"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        SPServiceInstance StartAppManagementServiceInstance {
            Name                 = " App Management Service"
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        SPServiceAppPool MainServiceAppPool {
            Name                 = $WEServiceAppPoolName
            ServiceAccount       = $WESPSvcCredsQualified.UserName
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPManagedAccount]CreateSPSvcManagedAccount"
        }

        SPWebApplication CreateMainWebApp {
            Name                   = " SharePoint - 80"
            ApplicationPool        = " SharePoint - 80"
            ApplicationPoolAccount = $WESPAppPoolCredsQualified.UserName
            AllowAnonymous         = $false
            DatabaseName           = $WESPDBPrefix + " Content_80"
            WebAppUrl              = " http://$WESharePointSitesAuthority/"
            Port                   = 80
            Ensure                 = " Present"
            PsDscRunAsCredential   = $WEDomainAdminCredsQualified
            DependsOn              = " [Script]RestartSPTimerAfterCreateSPFarm"
        }

        # SPShellAdmins AddShellAdmins {
        #     IsSingleInstance     = " Yes"
        #     Members              = @($WEDomainAdminCredsQualified.UserName)
        #     Databases            = @(
        #         @(MSFT_SPDatabasePermissions {
        #                 Name    = $WESPDBPrefix + " Content_80"
        #                 Members = @($WEDomainAdminCredsQualified.UserName)
        #             })
        #     )
        #     PsDscRunAsCredential = $WESPSetupCredsQualified
        #     DependsOn            = " [SPWebApplication]CreateMainWebApp"
        # }

        # Update GPO to ensure the root certificate of the CA is present in " cert:\LocalMachine\Root\" , otherwise certificate request will fail
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
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        # # Installing LDAPCP somehow updates SPClaimEncodingManager 
        # # But in SharePoint 2019 and Subscription, it causes an UpdatedConcurrencyException on SPClaimEncodingManager in SPTrustedIdentityTokenIssuer resource
        # # The only solution I've found is to force a reboot
        # Script ForceRebootBeforeCreatingSPTrust {
        #     # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        #     TestScript           = {
        #         return (Test-Path HKLM:\SOFTWARE\DscScriptExecution\flag_ForceRebootBeforeCreatingSPTrust)
        #     }
        #     SetScript            = {
        #         New-Item -Path HKLM:\SOFTWARE\DscScriptExecution\flag_ForceRebootBeforeCreatingSPTrust -Force
        #         $script:DSCMachineStatus = 1
        #     }
        #     GetScript            = { }
        #     PsDscRunAsCredential = $WEDomainAdminCredsQualified
        #     DependsOn            = " [SPFarmSolution]InstallLdapcpSolution"
        # }

        # PendingReboot RebootOnSignalFromForceRebootBeforeCreatingSPTrust {
        #     Name             = " RebootOnSignalFromForceRebootBeforeCreatingSPTrust"
        #     SkipCcmClientSDK = $true
        #     DependsOn        = " [Script]ForceRebootBeforeCreatingSPTrust"
        # }

        $apppoolUserName = $WESPAppPoolCredsQualified.UserName
        $domainAdminUserName = $WEDomainAdminCredsQualified.UserName
        Script SetFarmPropertiesForOIDC {
            SetScript            = 
            {
                $apppoolUserName = $using:apppoolUserName
                $domainAdminUserName = $using:domainAdminUserName
                $setupPath = Join-Path -Path $using:SetupPath -ChildPath " Certificates"
                if (!(Test-Path $setupPath -PathType Container)) {
                    New-Item -ItemType Directory -Force -Path $setupPath
                }
                $WEDCSetupPath = Join-Path -Path $using:DCSetupPath -ChildPath " Certificates"
                if (!(Test-Path $WEDCSetupPath -PathType Container)) {
                    New-Item -ItemType Directory -Force -Path $WEDCSetupPath
                }
                
                # Setup farm properties to work with OIDC
                # Create a self-signed certificate in 1st SharePoint Server of the farm
                $cookieCertificateName = " SharePoint OIDC nonce cert"
                $cookieCertificateFilePath = Join-Path -Path $setupPath -ChildPath " $cookieCertificateName"
                $cert = New-SelfSignedCertificate -KeyUsage None -KeyUsageProperty None -CertStoreLocation Cert:\LocalMachine\My -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider' -Subject " CN=$cookieCertificateName"
                Export-Certificate -Cert $cert -FilePath " $cookieCertificateFilePath.cer"
                Export-PfxCertificate -Cert $cert -FilePath " $cookieCertificateFilePath.pfx" -ProtectTo " $domainAdminUserName"
                Export-PfxCertificate -Cert $cert -FilePath " $WEDCSetupPath\$cookieCertificateName.pfx" -ProtectTo " $domainAdminUserName"

                # Grant access to the certificate private key.
                $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
                $fileName = $rsaCert.key.UniqueName
                $path = " $env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$fileName"
                $permissions = Get-Acl -Path $path
                $access_rule = New-Object -ErrorAction Stop System.Security.AccessControl.FileSystemAccessRule($apppoolUserName, 'Read', 'None', 'None', 'Allow')
                $permissions.AddAccessRule($access_rule)
                Set-Acl -Path $path -AclObject $permissions

                # Set farm properties
                $f = Get-SPFarm -ErrorAction Stop
                $f.Farm.Properties['SP-NonceCookieCertificateThumbprint'] = $cert.Thumbprint
                $f.Farm.Properties['SP-NonceCookieHMACSecretKey'] = " randomString$domainAdminUserName"
                $f.Farm.Update()
            }
            GetScript            =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ " Result" = " false" }
            }
            TestScript           = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                # Import-Module SharePointServer | Out-Null
                # $f = Get-SPFarm -ErrorAction Stop
                # if ($f.Farm.Properties.ContainsKey('SP-NonceCookieCertificateThumbprint') -eq $false) {
                if ((Get-ChildItem -Path " cert:\LocalMachine\My\" | Where-Object { $_.Subject -eq " CN=SharePoint Cookie Cert" }) -eq $null) {
                    return $false
                }
                else {
                    return $true
                }
            }
            DependsOn            = " [Script]RestartSPTimerAfterCreateSPFarm"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        SPTrustedIdentityTokenIssuer CreateSPTrust {
            Name                    = $WEDomainFQDN
            Description             = " Federation with $WEDomainFQDN"
            DefaultClientIdentifier = $WEAdfsOidcIdentifier
            MetadataEndPoint        = " https://adfs.$WEDomainFQDN/adfs/.well-known/openid-configuration"
            # RegisteredIssuerName       = " https://adfs.$WEDomainFQDN/adfs"
            # AuthorizationEndPointUri   = " https://adfs.$WEDomainFQDN/adfs/oauth2/authorize"
            # SignOutUrl                 = " https://adfs.$WEDomainFQDN/adfs/oauth2/logout"
            # SigningCertificateFilePath = " $WESetupPath\Certificates\ADFS Signing.cer"

            IdentifierClaim         = " http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
            ClaimsMappings          = @(
                MSFT_SPClaimTypeMapping {
                    Name              = " upn"
                    IncomingClaimType = " http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
                }
                MSFT_SPClaimTypeMapping {
                    Name              = " group"
                    IncomingClaimType = " http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                }
                MSFT_SPClaimTypeMapping {
                    Name              = " groupsid"
                    IncomingClaimType = " http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid"
                }
            )
            ClaimProviderName       = $WELdapcpSolutionName
            Ensure                  = " Present" 
            DependsOn               = " [Script]SetFarmPropertiesForOIDC" , " [Script]InstallLdapcpFeatures"
            PsDscRunAsCredential    = $WEDomainAdminCredsQualified
        }


        # ExtendMainWebApp might fail with error: " The web.config could not be saved on this IIS Web Site: C:\\inetpub\\wwwroot\\wss\\VirtualDirectories\\80\\web.config.\r\nThe process cannot access the file 'C:\\inetpub\\wwwroot\\wss\\VirtualDirectories\\80\\web.config' because it is being used by another process."
        # So I added resources between it and CreateMainWebApp to avoid it
        SPWebApplicationExtension ExtendMainWebApp {
            WebAppUrl            = " http://$WESharePointSitesAuthority/"
            Name                 = " SharePoint - 443"
            AllowAnonymous       = $false
            Url                  = " https://$WESharePointSitesAuthority.$WEDomainFQDN"
            Zone                 = " Intranet"
            Port                 = 443
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPWebApplication]CreateMainWebApp"
        }

        Script ConfigureLDAPCP {
            SetScript            = 
            {
                try {
                    Add-Type -AssemblyName " Yvand.LDAPCPSE, Version=1.0.0.0, Culture=neutral, PublicKeyToken=80be731bc1a1a740"
                    [Yvand.LdapClaimsProvider.LDAPCPSE]::CreateConfiguration()
                }
                catch {
                    Write-Verbose -Verbose -Message " Could not create LDAPCP configuration: $_"
                }
            }
            GetScript            =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ " Result" = " false" }
            }
            TestScript           = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                try {
                    Add-Type -AssemblyName " Yvand.LDAPCPSE, Version=1.0.0.0, Culture=neutral, PublicKeyToken=80be731bc1a1a740"
                    $config = [Yvand.LdapClaimsProvider.LDAPCPSE]::GetConfiguration()
                    if ($null -eq $config) {
                        return $false
                    }
                    else {
                        return $true
                    }
                }
                catch {
                    Write-Verbose -Verbose -Message " Could not test if LDAPCP configuration exists: $_"
                    return $true # Skip set if test fails
                }
            }
            DependsOn            = " [SPTrustedIdentityTokenIssuer]CreateSPTrust"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        SPWebAppAuthentication ConfigureMainWebAppAuthentication {
            WebAppUrl            = " http://$WESharePointSitesAuthority/"
            Default              = @(
                MSFT_SPWebAppAuthenticationMode {
                    AuthenticationMethod = " WindowsAuthentication"
                    WindowsAuthMethod    = " NTLM"
                }
            )
            Intranet             = @(
                MSFT_SPWebAppAuthenticationMode {
                    AuthenticationMethod   = " Federated"
                    AuthenticationProvider = $WEDomainFQDN
                }
            )
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPWebApplicationExtension]ExtendMainWebApp" , " [SPTrustedIdentityTokenIssuer]CreateSPTrust"
        }

        # Use SharePoint SE to generate the CSR and give the private key so it can manage it
        Script GenerateMainWebAppCertificate {
            SetScript            =
            {
                $dcName = $using:DCServerName
                $domainFQDN = $using:DomainFQDN
                $domainNetbiosName = $using:DomainNetbiosName
                $sharePointSitesAuthority = $using:SharePointSitesAuthority
                $appDomainIntranetFQDN = $using:AppDomainIntranetFQDN
                $setupPath = Join-Path -Path $using:SetupPath -ChildPath " Certificates"                
                if (!(Test-Path $setupPath -PathType Container)) {
                    New-Item -ItemType Directory -Force -Path $setupPath
                }

                Write-Verbose -Verbose -Message " Creating certificate request for CN=$sharePointSitesAuthority.$domainFQDN..."
                # Generate CSR
                New-SPCertificate -FriendlyName " $sharePointSitesAuthority Certificate" -KeySize 2048 -CommonName " $sharePointSitesAuthority.$domainFQDN" -AlternativeNames @(" *.$domainFQDN" , " *.$appDomainIntranetFQDN" ) -Organization " $domainNetbiosName" -Exportable -HashAlgorithm SHA256 -Path " $setupPath\$sharePointSitesAuthority.csr"

                # Submit CSR to CA
                & certreq.exe -submit -config " $dcName.$domainFQDN\$domainNetbiosName-$dcName-CA" -attrib " CertificateTemplate:Webserver" " $setupPath\$sharePointSitesAuthority.csr" " $setupPath\$sharePointSitesAuthority.cer" " $setupPath\$sharePointSitesAuthority.p7b" " $setupPath\$sharePointSitesAuthority.rsp"

                # Install certificate with its private key to certificate store
                # certreq -accept –machine " $setupPath\$sharePointSitesAuthority.cer"

                # Find the certificate
                # Get-ChildItem -Path cert:\localMachine\my | Where-Object{ $_.Subject -eq " CN=$sharePointSitesAuthority.$domainFQDN, O=$domainNetbiosName" } | Select-Object Thumbprint

                # # Export private key of the certificate
                # certutil -f -p " superpasse" -exportpfx A74D118AABD5B42F23BCD9083D3F6A3EF3BFD904 " $setupPath\$sharePointSitesAuthority.pfx"

                # # Import private key of the certificate into SharePoint
                # $password = ConvertTo-SecureString -AsPlainText -Force " <superpasse>"
                # Import-SPCertificate -Path " $setupPath\$sharePointSitesAuthority.pfx" -Password $password -Exportable
                Write-Verbose -Verbose -Message " Adding certificate 'CN=$sharePointSitesAuthority.$domainFQDN' to SharePoint store EndEntity..."
                $spCert = Import-SPCertificate -Path " $setupPath\$sharePointSitesAuthority.cer" -Exportable -Store EndEntity

                Write-Verbose -Verbose -Message " Extending web application to HTTPS zone using certificate 'CN=$sharePointSitesAuthority.$domainFQDN'..."
                Set-SPWebApplication -Identity " http://$sharePointSitesAuthority" -Zone Intranet -Port 443 -Certificate $spCert `
                    -SecureSocketsLayer:$true -AllowLegacyEncryption:$false -Url " https://$sharePointSitesAuthority.$domainFQDN"
                
                Write-Verbose -Verbose -Message " Finished."
            }
            GetScript            = { }
            TestScript           = 
            {
                $domainFQDN = $using:DomainFQDN
                $domainNetbiosName = $using:DomainNetbiosName
                $sharePointSitesAuthority = $using:SharePointSitesAuthority
                
                #;  $cert = Get-ChildItem -Path cert:\localMachine\my | Where-Object{ $_.Subject -eq " CN=$sharePointSitesAuthority.$domainFQDN, O=$domainNetbiosName" }
               ;  $cert = Get-SPCertificate -Identity " $sharePointSitesAuthority Certificate" -ErrorAction SilentlyContinue
                if ($null -eq $cert) {
                    return $false   # Run SetScript
                }
                else {
                    return $true    # Certificate is already created
                }
            }
            DependsOn            = " [Script]UpdateGPOToTrustRootCACert" , " [SPWebAppAuthentication]ConfigureMainWebAppAuthentication"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        SPCacheAccounts SetCacheAccounts {
            WebAppUrl            = " http://$WESharePointSitesAuthority/"
            SuperUserAlias       = " $WEDomainNetbiosName\$($WESPSuperUserCreds.UserName)"
            SuperReaderAlias     = " $WEDomainNetbiosName\$($WESPSuperReaderCreds.UserName)"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPWebApplication]CreateMainWebApp"
        }

        SPSite CreateRootSite {
            Url                  = " http://$WESharePointSitesAuthority/"
            OwnerAlias           = " i:0#.w|$WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)"
            SecondaryOwnerAlias  = " i:0$WETrustedIdChar.t|$WEDomainFQDN|$($WEDomainAdminCreds.UserName)@$WEDomainFQDN"
            Name                 = " root site"
            Template             = $WESPTeamSiteTemplate
            CreateDefaultGroups  = $true
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPWebAppAuthentication]ConfigureMainWebAppAuthentication"
        }

        # Create this site early, otherwise [SPAppCatalog]SetAppCatalogUrl may throw error " Cannot find an SPSite object with Id or Url: http://SPSites/sites/AppCatalog"
        SPSite CreateAppCatalog {
            Url                  = " http://$WESharePointSitesAuthority/sites/AppCatalog"
            OwnerAlias           = " i:0#.w|$WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)"
            SecondaryOwnerAlias  = " i:0$WETrustedIdChar.t|$WEDomainFQDN|$($WEDomainAdminCreds.UserName)@$WEDomainFQDN"
            Name                 = " AppCatalog"
            Template             = " APPCATALOG#0"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPWebAppAuthentication]ConfigureMainWebAppAuthentication"
        }

        #**********************************************************
        # Additional configuration
        #**********************************************************
        SPSite CreateMySiteHost {
            Url                      = " http://$WEMySiteHostAlias/"
            HostHeaderWebApplication = " http://$WESharePointSitesAuthority/"
            OwnerAlias               = " i:0#.w|$WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)"
            SecondaryOwnerAlias      = " i:0$WETrustedIdChar.t|$WEDomainFQDN|$($WEDomainAdminCreds.UserName)@$WEDomainFQDN"
            Name                     = " MySite host"
            Template                 = " SPSMSITEHOST#0"
            PsDscRunAsCredential     = $WEDomainAdminCredsQualified
            DependsOn                = " [SPWebAppAuthentication]ConfigureMainWebAppAuthentication"
        }

        SPSiteUrl SetMySiteHostIntranetUrl {
            Url                  = " http://$WEMySiteHostAlias/"
            Intranet             = " https://$WEMySiteHostAlias.$WEDomainFQDN"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPSite]CreateMySiteHost"
        }

        SPManagedPath CreateMySiteManagedPath {
            WebAppUrl            = " http://$WESharePointSitesAuthority/"
            RelativeUrl          = " personal"
            Explicit             = $false
            HostHeader           = $true
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPSite]CreateMySiteHost"
        }

        SPUserProfileServiceApp CreateUserProfileServiceApp {
            Name                 = $WEUpaServiceName
            ApplicationPool      = $WEServiceAppPoolName
            MySiteHostLocation   = " http://$WEMySiteHostAlias/"
            ProfileDBName        = $WESPDBPrefix + " UPA_Profiles"
            SocialDBName         = $WESPDBPrefix + " UPA_Social"
            SyncDBName           = $WESPDBPrefix + " UPA_Sync"
            EnableNetBIOS        = $false
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPServiceAppPool]MainServiceAppPool" , " [SPServiceInstance]UPAServiceInstance" , " [SPSite]CreateMySiteHost"
        }

        # Creating this site takes about 1 min but it is not so useful, skip it
        # SPSite CreateDevSite
        # {
        #     Url                  = " http://$WESharePointSitesAuthority/sites/dev"
        #     OwnerAlias           = " i:0#.w|$WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)"
        #     SecondaryOwnerAlias  = " i:0$WETrustedIdChar.t|$WEDomainFQDN|$($WEDomainAdminCreds.UserName)@$WEDomainFQDN"
        #     Name                 = " Developer site"
        #     Template             = " DEV#0"
        #     PsDscRunAsCredential = $WEDomainAdminCredsQualified
        #     DependsOn            = " [SPWebAppAuthentication]ConfigureMainWebAppAuthentication"
        # }

        SPSite CreateHNSC1 {
            Url                      = " http://$WEHNSC1Alias/"
            HostHeaderWebApplication = " http://$WESharePointSitesAuthority/"
            OwnerAlias               = " i:0#.w|$WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)"
            SecondaryOwnerAlias      = " i:0$WETrustedIdChar.t|$WEDomainFQDN|$($WEDomainAdminCreds.UserName)@$WEDomainFQDN"
            Name                     = " $WEHNSC1Alias site"
            Template                 = $WESPTeamSiteTemplate
            CreateDefaultGroups      = $true
            PsDscRunAsCredential     = $WEDomainAdminCredsQualified
            DependsOn                = " [SPWebAppAuthentication]ConfigureMainWebAppAuthentication"
        }

        SPSiteUrl SetHNSC1IntranetUrl {
            Url                  = " http://$WEHNSC1Alias/"
            Intranet             = " https://$WEHNSC1Alias.$WEDomainFQDN"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPSite]CreateHNSC1"
        }

        SPSubscriptionSettingsServiceApp CreateSubscriptionServiceApp {
            Name                 = " Subscription Settings Service Application"
            ApplicationPool      = $WEServiceAppPoolName
            DatabaseName         = " $($WESPDBPrefix)SubscriptionSettings"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPServiceAppPool]MainServiceAppPool" , " [SPServiceInstance]StartSubscriptionSettingsServiceInstance"
        }

        SPAppManagementServiceApp CreateAppManagementServiceApp {
            Name                 = " App Management Service Application"
            ApplicationPool      = $WEServiceAppPoolName
            DatabaseName         = " $($WESPDBPrefix)AppManagement"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPServiceAppPool]MainServiceAppPool" , " [SPServiceInstance]StartAppManagementServiceInstance"
        }

        SPServiceAppSecurity SetUserProfileServiceSecurity {
            ServiceAppName       = $WEUpaServiceName
            SecurityType         = " SharingPermissions"
            MembersToInclude     = @(
                # Grant spsvc full control to UPA to allow newsfeeds to work properly
                MSFT_SPServiceAppSecurityEntry {
                    Username     = $WESPSvcCredsQualified.UserName
                    AccessLevels = @(" Full Control" )
                };
                MSFT_SPServiceAppSecurityEntry {
                    Username     = $WEDomainAdminCredsQualified.UserName
                    AccessLevels = @(" Full Control" )
                }
            )
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            #DependsOn           = " [Script]RefreshLocalConfigCache"
            DependsOn            = " [SPUserProfileServiceApp]CreateUserProfileServiceApp"
        }

        # Configure the SPTrustedBackedByUPAClaimProvider as much as possible. The remaining steps are:
        # - In User Profile Service:
        #    - Create a synchronization connection that uses the authentication type " Trusted Claims Provider Authentication"
        #    - Edit profile property " Claim User Identifier" to remove default mapping, and readd one that uses the LDAP attribute " userPrincipalName"
        # - In the trust: Associate the claims provider: $trust = Get-SPTrustedIdentityTokenIssuer -ErrorAction Stop " contoso.local" ; $trust.ClaimProviderName = " contoso.local" ; $trust.Update();
        Script ConfigureUPAClaimProvider {
            SetScript            = 
            {
                try {
                    $spTrustName = $using:DomainFQDN
                    $spSiteUrl = " http://$($using:SharePointSitesAuthority)/"
                    Write-Verbose -Verbose -Message " Start configuration for ConfigureUPAClaimProvider using spTrustName '$($spTrustName)' and spSiteUrl '$($spSiteUrl)'"                

                    # LanguageSynchronizationJob must be executed before updating profile properties, to ensure their property DisplayNameLocalized is set with a localized value
                    # LanguageSynchronizationJob basically populates SQL table [SPDSC_UPA_Profiles].[upa].[PropertyListLoc]
                    # If this job is not run, $property.CoreProperty.Commit() will throw: Exception calling " Commit" with " 0" argument(s): " The display name must be specified in order to create a property." 
                   ;  $job = Get-SPTimerJob -Type " Microsoft.Office.Server.Administration.UserProfileApplication+LanguageSynchronizationJob"
                    $job.Execute()
                    
                    # Gets the trust
                   ;  $trust = Get-SPTrustedIdentityTokenIssuer -Identity $spTrustName -ErrorAction SilentlyContinue
                    if ($null -eq $trust) {
                        Write-Verbose -Verbose -Message " Could not get the trust $spTrustName, give up"
                        return;
                    }

                    # Creates the claims provider if it does not already exist
                    $claimsProvider = Get-SPClaimProvider -Identity $spTrustName -ErrorAction SilentlyContinue
                    if ($null -eq $claimsProvider) {
                        $claimsProviderName = " UPA Claim Provider"
                        $claimsProvider = New-SPClaimProvider -AssemblyName " Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, publicKeyToken=71e9bce111e9429c" -Default:$false `
                            -DisplayName $claimsProviderName -Description $claimsProviderName -Type " Microsoft.SharePoint.Administration.Claims.SPTrustedBackedByUPAClaimProvider" `
                            -TrustedTokenIssuer $trust
                    }

                    # Running this set below would set SPTrustedBackedByUPAClaimProvider as the active claims provider for this trust
                    # But it wouldn't work since properties " SPS-ClaimProviderID" and " SPS-ClaimProviderType" of trusted profiles are not set
                    # Set-SPTrustedIdentityTokenIssuer -ErrorAction Stop $trust -ClaimProvider $claimsProvider -IsOpenIDConnect

                    # Sets the property IsPeoplePickerSearchable on specific profile properties
                    $site = Get-SPSite -Identity $spSiteUrl -ErrorAction SilentlyContinue
                    $context = Get-SPServiceContext -ErrorAction Stop $site -ErrorAction SilentlyContinue
                    $psm = [Microsoft.Office.Server.UserProfiles.ProfileSubTypeManager]::Get($context)
                    $ps = $psm.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName([Microsoft.Office.Server.UserProfiles.ProfileType]::User))
                    $properties = $ps.Properties

                    $propertyNames = @('FirstName', 'LastName', 'SPS-ClaimID', 'PreferredName')
                    foreach ($propertyName in $propertyNames) { 
                        $property = $properties.GetPropertyByName($propertyName)
                        if ($property) {
                            Write-Verbose -Verbose -Message " Updating property $($propertyName)"
                            $property.CoreProperty.IsPeoplePickerSearchable = $true 
                            $property.CoreProperty.Commit()
                            Write-Verbose -Verbose -Message " Updated property $($propertyName) with IsPeoplePickerSearchable: $($property.CoreProperty.IsPeoplePickerSearchable)"
                        }
                    }
                    Write-Verbose -Verbose -Message " Finished configuration for ConfigureUPAClaimProvider"
                }
                catch [ Microsoft.Office.Server.UserProfiles.PartitionNotFoundException ] {
                    Write-Verbose -Verbose -Message " Caught PartitionNotFoundException, likely caused by Execute() on LanguageSynchronizationJob. Started after enabling secure SQL connection, which became necessary with Subscription 25H1"
                    Write-Verbose -Verbose -Message " Exception message: $($_.Exception.Message)"
                }
                catch {
                    Write-Verbose -Verbose -Message " An error occurred in ConfigureUPAClaimProvider.Set: $($_.Exception.Message)"
                }
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
            DependsOn            = " [SPTrustedIdentityTokenIssuer]CreateSPTrust" , " [SPSite]CreateRootSite" , " [SPUserProfileServiceApp]CreateUserProfileServiceApp"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        SPUserProfileSyncConnection ADImportConnection {
            UserProfileService    = $WEUpaServiceName
            Forest                = $WEDomainFQDN
            Name                  = $WEDomainFQDN
            ConnectionCredentials = $WESPADDirSyncCredsQualified
            Server                = $WEDomainLDAPPath
            UseSSL                = $true
            Port                  = 636
            IncludedOUs           = @(" CN=Users,$WEDomainLDAPPath" , $WEAdditionalUsersPath)
            Force                 = $false
            ConnectionType        = " ActiveDirectory"
            UseDisabledFilter     = $true
            PsDscRunAsCredential  = $WEDomainAdminCredsQualified
            DependsOn             = " [SPUserProfileServiceApp]CreateUserProfileServiceApp"
        }

        SPSecurityTokenServiceConfig ConfigureSTS {
            Name                  = " SecurityTokenServiceManager"
            UseSessionCookies     = $false
            AllowOAuthOverHttp    = $true
            AllowMetadataOverHttp = $true
            IsSingleInstance      = " Yes"
            PsDscRunAsCredential  = $WEDomainAdminCredsQualified
            DependsOn             = " [SPFarm]CreateSPFarm"
        }        

        # Execute this action some time after CreateAppManagementServiceApp to avoid this error: An update conflict has occurred, and you must re-try this action. The object AppManagementService was updated by CONTOSO\\spsetup, in the wsmprovhost (5136) process, on machine SP
        SPAppDomain ConfigureLocalFarmAppUrls {
            AppDomain            = $WEAppDomainFQDN
            Prefix               = " addin"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPSubscriptionSettingsServiceApp]CreateSubscriptionServiceApp" , " [SPAppManagementServiceApp]CreateAppManagementServiceApp"
        }        

        SPWebApplicationAppDomain ConfigureAppDomainDefaultZone {
            WebAppUrl            = " http://$WESharePointSitesAuthority"
            AppDomain            = $WEAppDomainFQDN
            Zone                 = " Default"
            Port                 = 80
            SSL                  = $false
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPAppDomain]ConfigureLocalFarmAppUrls"
        }

        SPWebApplicationAppDomain ConfigureAppDomainIntranetZone {
            WebAppUrl            = " http://$WESharePointSitesAuthority"
            AppDomain            = $WEAppDomainIntranetFQDN
            Zone                 = " Intranet"
            Port                 = 443
            SSL                  = $true
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPAppDomain]ConfigureLocalFarmAppUrls"
        }

        SPAppCatalog SetAppCatalogUrl {
            SiteUrl              = " http://$WESharePointSitesAuthority/sites/AppCatalog"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPSite]CreateAppCatalog" , " [SPAppManagementServiceApp]CreateAppManagementServiceApp"
        }
        
        # This team site is tested by VM FE to wait before joining the farm, so it acts as a milestone and it should be created only when all SharePoint services are created
        # If VM FE joins the farm while a SharePoint service is creating here, it may block its creation forever.
        SPSite CreateTeamSite {
            Url                  = " http://$WESharePointSitesAuthority/sites/team"
            OwnerAlias           = " i:0#.w|$WEDomainNetbiosName\$($WEDomainAdminCreds.UserName)"
            SecondaryOwnerAlias  = " i:0$WETrustedIdChar.t|$WEDomainFQDN|$($WEDomainAdminCreds.UserName)@$WEDomainFQDN"
            Name                 = " Team site"
            Template             = $WESPTeamSiteTemplate
            CreateDefaultGroups  = $true
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPWebAppAuthentication]ConfigureMainWebAppAuthentication" , " [SPWebApplicationAppDomain]ConfigureAppDomainDefaultZone" , " [SPWebApplicationAppDomain]ConfigureAppDomainIntranetZone" , " [SPAppCatalog]SetAppCatalogUrl"
        }

        CertReq GenerateAddinsSiteCertificate {
            CARootName          = " $WEDomainNetbiosName-$WEDCServerName-CA"
            CAServerFQDN        = " $WEDCServerName.$WEDomainFQDN"
            Subject             = " $WEAddinsSiteDNSAlias.$($WEDomainFQDN)"
            FriendlyName        = " Provider-hosted addins site certificate"
            SubjectAltName      = " dns=$WEAddinsSiteDNSAlias.$($WEDomainFQDN)"
            KeyLength           = '2048'
            Exportable          = $true
            ProviderName        = '" Microsoft RSA SChannel Cryptographic Provider" '
            OID                 = '1.3.6.1.5.5.7.3.1'
            KeyUsage            = '0xa0'
            CertificateTemplate = 'WebServer'
            AutoRenew           = $true
            Credential          = $WEDomainAdminCredsQualified
            DependsOn           = " [Script]UpdateGPOToTrustRootCACert"
        }

        File CreateAddinsSiteDirectory {
            DestinationPath = " C:\inetpub\wwwroot\addins"
            Type            = " Directory"
            Ensure          = " Present"
            DependsOn       = " [SPFarm]CreateSPFarm"
        }

        WebAppPool CreateAddinsSiteApplicationPool {
            Name                  = $WEAddinsSiteName
            State                 = " Started"
            managedPipelineMode   = 'Integrated'
            managedRuntimeLoader  = 'webengine4.dll'
            managedRuntimeVersion = 'v4.0'
            identityType          = " SpecificUser"
            Credential            = $WESPSvcCredsQualified
            Ensure                = " Present"
            PsDscRunAsCredential  = $WEDomainAdminCredsQualified
            DependsOn             = " [SPFarm]CreateSPFarm"
        }

        Website CreateAddinsSite {
            Name                 = $WEAddinsSiteName
            State                = " Started"
            PhysicalPath         = " C:\inetpub\wwwroot\addins"
            ApplicationPool      = $WEAddinsSiteName
            AuthenticationInfo   = DSC_WebAuthenticationInformation {
                Anonymous = $true
                Windows   = $true
            }
            BindingInfo          = @(
                DSC_WebBindingInformation {
                    Protocol = " HTTP"
                    Port     = 20080
                }
                DSC_WebBindingInformation {
                    Protocol             = " HTTPS"
                    Port                 = 20443
                    CertificateStoreName = " My"
                    CertificateSubject   = " $WEAddinsSiteDNSAlias.$($WEDomainFQDN)"
                }
            )
            Ensure               = " Present"
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [CertReq]GenerateAddinsSiteCertificate" , " [File]CreateAddinsSiteDirectory" , " [WebAppPool]CreateAddinsSiteApplicationPool"
        }

        Script CopyIISWelcomePageToAddinsSite {
            SetScript            = 
            {
                Copy-Item -Path " C:\inetpub\wwwroot\*" -Filter " iisstart*" -Destination " C:\inetpub\wwwroot\addins"
            }
            GetScript            =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ " Result" = " false" }
            }
            TestScript           = 
            {
                if ( (Get-ChildItem -Path " C:\inetpub\wwwroot\addins" -Name " iisstart*" ) -eq $null) {
                    return $false
                }
                else {
                    return $true
                }
            }
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [WebSite]CreateAddinsSite"
        }

        CertReq GenerateHighTrustAddinsCert {
            CARootName          = " $WEDomainNetbiosName-$WEDCServerName-CA"
            CAServerFQDN        = " $WEDCServerName.$WEDomainFQDN"
            Subject             = " HighTrustAddins"
            FriendlyName        = " Sign OAuth tokens of high-trust add-ins"
            KeyLength           = '2048'
            Exportable          = $true
            ProviderName        = '" Microsoft RSA SChannel Cryptographic Provider" '
            OID                 = '1.3.6.1.5.5.7.3.1'
            KeyUsage            = '0xa0'
            CertificateTemplate = 'WebServer'
            AutoRenew           = $true
            Credential          = $WEDomainAdminCredsQualified
            DependsOn           = " [Script]UpdateGPOToTrustRootCACert"
        }

        Script ExportHighTrustAddinsCert {
            SetScript  = 
            {
                $destinationPath = Join-Path -Path $using:SetupPath -ChildPath " Certificates"
                $certSubject = " HighTrustAddins"
                $certName = " HighTrustAddins.cer"
                $certFullPath = [System.IO.Path]::Combine($destinationPath, $certName)
                Write-Verbose -Verbose -Message " Exporting public key of certificate with subject $certSubject to $certFullPath..."
                New-Item -ErrorAction Stop $destinationPath -Type directory -ErrorAction SilentlyContinue
                $signingCert = Get-ChildItem -Path " cert:\LocalMachine\My\" -DnsName " $certSubject"
                $signingCert | Export-Certificate -FilePath $certFullPath
                Write-Verbose -Verbose -Message " Public key of certificate with subject $certSubject successfully exported to $certFullPath."
            }
            GetScript  =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ " Result" = " false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn  = " [CertReq]GenerateHighTrustAddinsCert"
        }

        SPTrustedSecurityTokenIssuer CreateHighTrustAddinsTrustedIssuer {
            Name                           = " HighTrustAddins"
            Description                    = " Trust for Provider-hosted high-trust add-ins"
            RegisteredIssuerNameIdentifier = " 22222222-2222-2222-2222-222222222222"
            IsTrustBroker                  = $true
            SigningCertificateFilePath     = " $WESetupPath\Certificates\HighTrustAddins.cer"
            Ensure                         = " Present"
            DependsOn                      = " [Script]ExportHighTrustAddinsCert"
            PsDscRunAsCredential           = $WEDomainAdminCredsQualified
        }

        Script WarmupSites {
            SetScript            =
            {
                $jobBlock = {
                    $uri = $args[0]
                    try {
                        Write-Verbose -Verbose -Message " Connecting to $uri..."
                        # -UseDefaultCredentials: Does NTLM authN
                        # -UseBasicParsing: Avoid exception because IE was not first launched yet
                        # Expected traffic is HTTP 401/302/200, and $WEResponse.StatusCode is 200
                        Invoke-WebRequest -Uri $uri -UseDefaultCredentials -TimeoutSec 40 -UseBasicParsing -ErrorAction SilentlyContinue
                        Write-Verbose -Verbose -Message " Connected successfully to $uri"
                    }
                    catch [System.Exception] {
                        Write-Verbose -Verbose -Message " Unexpected error while connecting to '$uri': $_"
                    }
                    catch {
                        # It may typically be a System.Management.Automation.ErrorRecord, which does not inherit System.Exception
                        Write-Verbose -Verbose -Message " Unexpected error while connecting to '$uri'"
                    }
                }
                [System.Management.Automation.Job[]] $jobs = @()
                $spsite = " http://$($using:ComputerName):$($using:SharePointCentralAdminPort)/"
                Write-Verbose -Verbose -Message " Warming up '$spsite'..."
                $jobs = $jobs + Start-Job -ScriptBlock $jobBlock -ArgumentList @($spsite)
                $spsite = " http://$($using:SharePointSitesAuthority)/"
                Write-Verbose -Verbose -Message " Warming up '$spsite'..."
                $jobs = $jobs + Start-Job -ScriptBlock $jobBlock -ArgumentList @($spsite)

                # Must wait for the jobs to complete, otherwise they do not actually run
                Receive-Job -Job $jobs -AutoRemoveJob -Wait
            }
            GetScript            = { return @{ " Result" = " false" } } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript           = { return $false } # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
            DependsOn            = " [SPSite]CreateRootSite"
        }

        Script CreatePersonalSites {
            SetScript            =
            {
                # Need to wrap the creation of personal sites in a job to avoid the error below when calling CreatePersonalSiteEnque($false):
                # Could not enqueue creation of personal site for 'i:0#.w|contoso\yvand': Exception calling " CreatePersonalSiteEnque" with " 1" argument(s): " Attempted to perform an unauthorized operation."
                $jobBlock = {
                    $uri = $args[0]
                    $accountPattern_WinClaims = $args[1]
                    $accountPattern_Trusted = $args[2]
                    $directoryBase = $args[3]

                    try {
                        $site = Get-SPSite -Identity $uri -ErrorAction SilentlyContinue
                        $context = Get-SPServiceContext -ErrorAction Stop $site -ErrorAction SilentlyContinue
                       ;  $upm = New-Object -ErrorAction Stop Microsoft.Office.Server.UserProfiles.UserProfileManager($context)
                        Write-Verbose -Verbose -Message " Got UserProfileManager"
                    }
                    catch {
                        Write-Verbose -Verbose -Message " Unable to get UserProfileManager: $_"
                        # If Write-Error is called, then the Script resource is going to failed state
                        # Write-Error -Exception $_ -Message " Unable to get UserProfileManager for '$($account.AccountName)'"
                        return
                    }

                    # Accessing $using:DomainAdminCredsQualified here somehow causes a deserialization error, so use $env:UserName instead
                    [object []];  $accounts = @(
                        @{
                            " AccountName"   = $accountPattern_WinClaims -f $env:UserName;
                            " PreferredName" = $env:UserName;
                        },
                        @{
                            " AccountName"   = $accountPattern_Trusted -f $env:UserName;
                            " PreferredName" = $env:UserName;
                        }
                    )
                    
                    $directoryUsers = Get-ADUser -Filter " objectClass -like 'user'" -Properties @(" SamAccountName" , " displayName" ) -SearchBase $directoryBase #-ResultSetSize 5
                    foreach ($directoryUser in $directoryUsers) {
                       ;  $accounts = $accounts + @{
                            " AccountName"   = $accountPattern_WinClaims -f $directoryUser.SamAccountName;
                            " PreferredName" = $directoryUser[" displayName" ];
                        },
                        @{
                            " AccountName"   = $accountPattern_Trusted -f $directoryUser.SamAccountName;
                            " PreferredName" = $directoryUser[" displayName" ];
                        }
                    }

                    foreach ($account in $accounts) {
                        $userProfile = $null
                        try {
                           ;  $userProfile = $upm.GetUserProfile($account.AccountName)
                            Write-Verbose -Verbose -Message " Got existing user profile for '$($account.AccountName)'"
                        }
                        catch {
                           ;  $userProfile = $upm.CreateUserProfile($account.AccountName, $account.PreferredName);
                            Write-Verbose -Verbose -Message " Successfully created user profile for '$($account.AccountName)'"
                        }
                    
                        if ($null -eq $userProfile) {
                            Write-Verbose -Verbose -Message " Unable to get/create the profile for '$($account.AccountName)', give up"
                            continue
                        }
                        
                        if ($null -eq $userProfile.PersonalSite) {
                            Write-Verbose -Verbose -Message " Adding creation of personal site for '$($account.AccountName)' to the queue..."
                            try {
                                $userProfile.CreatePersonalSiteEnque($false)
                                Write-Verbose -Verbose -Message " Successfully enqueued the creation of personal site for '$($account.AccountName)'"
                            }
                            catch {
                                Write-Verbose -Verbose -Message " Could not enqueue creation of personal site for '$($account.AccountName)': $_"
                            }
                        }
                        else {
                            Write-Verbose -Verbose -Message " Personal site for '$($account.AccountName)' already exists, nothing to do"
                        }
                    }

                    # # LanguageSynchronizationJob must be executed before updating profile properties, to ensure their property DisplayNameLocalized is set with a localized value
                    # # This is populated in SQL table [SPDSC_UPA_Profiles].[upa].[PropertyListLoc]
                    # # If this value is not set, $property.CoreProperty.Commit() will throw: Exception calling " Commit" with " 0" argument(s): " The display name must be specified in order to create a property." 
                    # $job = Get-SPTimerJob -Type " Microsoft.Office.Server.Administration.UserProfileApplication+LanguageSynchronizationJob"
                    # $job.Execute()

                    # $psm = [Microsoft.Office.Server.UserProfiles.ProfileSubTypeManager]::Get($context)
                    #;  $ps = $psm.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName([Microsoft.Office.Server.UserProfiles.ProfileType]::User))
                    #;  $properties = $ps.Properties
                    # $properties.Count # will call LoadProperties()
                    # #$properties.GetType().GetMethod(" LoadProperties" , [System.Reflection.BindingFlags]" NonPublic, Instance" ).Invoke($properties, $null);
                    # $WEPropertyNames = @('FirstName', 'LastName', 'SPS-ClaimID', 'PreferredName')
                    # foreach ($propertyName in $WEPropertyNames) { 
                    #     $property = $properties.GetPropertyByName($propertyName)
                    #     if ($property) {
                    #         Write-Verbose -Verbose -Message " Checking property $($propertyName)"
                    #         $property.CoreProperty.DisplayNameLocalized # Test to avoid error " The display name must be specified in order to create a property."
                    #         $m_DisplayNamesValue = $property.CoreProperty.GetType().GetField(" m_DisplayNames" , [System.Reflection.BindingFlags]" NonPublic, Instance" ).GetValue($property.CoreProperty)
                    #         if ($m_DisplayNamesValue) {
                    #             Write-Verbose -Verbose -Message " Property $($propertyName) has m_DisplayNamesValue.DefaultLanguage $($m_DisplayNamesValue.DefaultLanguage) and m_DisplayNamesValue.Count $($m_DisplayNamesValue.Count)"
                    #         }
                    #         $property.CoreProperty.IsPeoplePickerSearchable = $true
                    #         # Somehow this may throw this error: Exception calling " Commit" with " 0" argument(s): " The display name must be specified in order to create a property."
                    #         $property.CoreProperty.Commit()
                    #         Write-Verbose -Verbose -Message " Updated property $($propertyName) with IsPeoplePickerSearchable: $($property.CoreProperty.IsPeoplePickerSearchable)"
                    #     }
                    # }
                }
                $uri = " http://$($using:SharePointSitesAuthority)/"
                $accountPattern_WinClaims = " i:0#.w|$($using:DomainNetbiosName)\{0}"
                $accountPattern_Trusted = " i:0$($using:TrustedIdChar).t|$($using:DomainFQDN)|{0}@$($using:DomainFQDN)"
                $job = Start-Job -ScriptBlock $jobBlock -ArgumentList @($uri, $accountPattern_WinClaims, $accountPattern_Trusted, $using:AdditionalUsersPath)
                Receive-Job -Job $job -AutoRemoveJob -Wait
            }
            GetScript            = { return @{ " Result" = " false" } } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript           = { return $false } # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        Script CreateShortcuts {
            SetScript            =
            {
                $WEWshShell = New-Object -comObject WScript.Shell
                # Shortcut to the setup folder
                $WEShortcut = $WEWshShell.CreateShortcut(" $WEHome\Desktop\Setup data.lnk" )
                $WEShortcut.TargetPath = $using:SetupPath
                $WEShortcut.Save()

                # Shortcut for SharePoint Central Administration
                $WEShortcut = $WEWshShell.CreateShortcut(" $WEHome\Desktop\SharePoint Central Administration.lnk" )
                $WEShortcut.TargetPath = " C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\BIN\psconfigui.exe"
                $WEShortcut.Arguments = " -cmd showcentraladmin"
                $WEShortcut.Save()

                # Shortcut for SharePoint Products Configuration Wizard
                $WEShortcut = $WEWshShell.CreateShortcut(" $WEHome\Desktop\SharePoint Products Configuration Wizard.lnk" )
                $WEShortcut.TargetPath = " C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\BIN\psconfigui.exe"
                $WEShortcut.Save()

                # Shortcut for SharePoint Management Shell
                $WEShortcut = $WEWshShell.CreateShortcut(" $WEHome\Desktop\SharePoint Management Shell.lnk" )
                $WEShortcut.TargetPath = " C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe"
                $WEShortcut.Arguments = " -NoExit -Command "" & '${env:ProgramFiles}\WindowsPowerShell\Modules\SharePointServer\SharePoint.ps1'"
                $WEShortcut.Save()
            }
            GetScript            = { return @{ " Result" = " false" } } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript           = { return $false } # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
            PsDscRunAsCredential = $WEDomainAdminCredsQualified
        }

        # if ($WEEnableAnalysis) {
        #     # This resource is for analysis of dsc logs only and totally optionnal
        #     Script parseDscLogs
        #     {
        #         TestScript = { return (Test-Path " $setupPath\parse-dsc-logs.py" -PathType Leaf) }
        #         SetScript = {
        #             $setupPath = $using:SetupPath
        #             $localScriptPath = " $setupPath\parse-dsc-logs.py"
        #             New-Item -ItemType Directory -Force -Path $setupPath

        #             $url = " https://gist.githubusercontent.com/Yvand/777a2e97c5d07198b926d7bb4f12ab04/raw/parse-dsc-logs.py"
        #             $downloader = New-Object -TypeName System.Net.WebClient
        #             $downloader.DownloadFile($url, $localScriptPath)

        #             $dscExtensionPath = " C:\WindowsAzure\Logs\Plugins\Microsoft.Powershell.DSC"
        #             $folderWithMaxVersionNumber = Get-ChildItem -Directory -Path $dscExtensionPath | Where-Object { $_.Name -match " ^[\d\.]+$" } | Sort-Object -Descending -Property Name | Select-Object -First 1
        #             $fullPathToDscLogs = [System.IO.Path]::Combine($dscExtensionPath, $folderWithMaxVersionNumber)
                    
        #             # Start python script
        #             Write-Verbose -Verbose -Message " Run python `" $localScriptPath`" `" $fullPathToDscLogs`" ..."
        #             #Start-Process -FilePath " powershell" -ArgumentList " python `" $localScriptPath`" `" $fullPathToDscLogs`""
        #             #invoke-expression " cmd /c start powershell -Command { $localScriptPath $fullPathToDscLogs }"
        #             python " $localScriptPath" " $fullPathToDscLogs"

        #             # Create a shortcut to the DSC logs folder
        #             $WEWshShell = New-Object -comObject WScript.Shell
        #             $WEShortcut = $WEWshShell.CreateShortcut(" $WEHome\Desktop\DSC logs.lnk" )
        #             $WEShortcut.TargetPath = $fullPathToDscLogs
        #             $WEShortcut.Save()

        #             # Create shortcut to DSC configuration folder
        #             $WEShortcut = $WEWshShell.CreateShortcut(" $WEHome\Desktop\DSC config.lnk" )
        #             $WEShortcut.TargetPath = " C:\Packages\Plugins\Microsoft.Powershell.DSC\{0}\DSCWork\ConfigureSPSE.0" -f $folderWithMaxVersionNumber
        #             $WEShortcut.Save()
        #         }
        #         GetScript = { }
        #         DependsOn            = " [cChocoPackageInstaller]InstallPython"
        #         PsDscRunAsCredential = $WEDomainAdminCredsQualified
        #     }
        # }

        Script DscStatus_Finished {
            SetScript  =
            {
                " $(Get-Date -Format u)`t$($using:ComputerName)`tDSC Configuration on finished." | Out-File -FilePath $using:DscStatusFilePath -Append
            }
            GetScript  = { } # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
            TestScript = { return $false } # If the TestScript returns $false, DSC executes the SetScript to bring the node back to the desired state
        }
    }
}

[CmdletBinding()]
function WE-Get-LatestGitHubRelease -ErrorAction Stop {
    [OutputType([string])]
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [string] $WERepo,
        [string] $WEArtifact,
        [string] $WEReleaseId
    )
    # # Force protocol TLS 1.2 in Invoke-WebRequest to fix TLS/SSL connection error with GitHub in Windows Server 2012 R2, as documented in https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-update-1802
    # [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $latestRelease = Invoke-WebRequest " https://api.github.com/repos/$WERepo/releases/$WEReleaseId" -Headers @{" Accept" = " application/json" } -UseBasicParsing
    $json = $latestRelease.Content | ConvertFrom-Json
    $asset = $json.assets | Where-Object { $_.name -like $WEArtifact }
    $assetUrl = $asset.browser_download_url
    return $assetUrl
}

[CmdletBinding()]
function WE-Get-NetBIOSName -ErrorAction Stop {
    [OutputType([string])]
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [string]$WEDomainFQDN
    )

    if ($WEDomainFQDN.Contains('.')) {
        $length = $WEDomainFQDN.IndexOf('.')
        if ( $length -ge 16) {
            $length = 15
        }
        return $WEDomainFQDN.Substring(0, $length)
    }
    else {
        if ($WEDomainFQDN.Length -gt 15) {
            return $WEDomainFQDN.Substring(0, 15)
        }
        else {
            return $WEDomainFQDN
        }
    }
}

<#
help ConfigureSPVM

$password = ConvertTo-SecureString -String " mytopsecurepassword" -AsPlainText -Force
$WEDomainAdminCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " yvand" , $password
$WESPSetupCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spsetup" , $password
$WESPFarmCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spfarm" , $password
$WESPSvcCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spsvc" , $password
$WESPAppPoolCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spapppool" , $password
$WESPADDirSyncCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spaddirsync" , $password
$WESPPassphraseCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " Passphrase" , $password
$WESPSuperUserCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spSuperUser" , $password
$WESPSuperReaderCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " spSuperReader" , $password
$WEDNSServerIP = " 10.1.1.4"
$WEDomainFQDN = " contoso.local"
$WEDCServerName = " DC"
$WESQLServerName = " SQL"
$WESQLAlias = " SQLAlias"
$WESharePointVersion = " Subscription-RTM"
$WESharePointSitesAuthority = " spsites"
$WESharePointCentralAdminPort = 5000; 
$WEEnableAnalysis = $true; 
$WESharePointBits = @(
    @{
        Label = " RTM" ; 
        Packages = @(
            @{ DownloadUrl = " https://go.microsoft.com/fwlink/?linkid=2171943" ; ChecksumType = " SHA256" ; Checksum = " C576B847C573234B68FC602A0318F5794D7A61D8149EB6AE537AF04470B7FC05" }
        )
    },
    @{
        Label = " 22H2" ; 
        Packages = @(
            @{ DownloadUrl = " https://download.microsoft.com/download/8/d/f/8dfcb515-6e49-42e5-b20f-5ebdfd19d8e7/wssloc-subscription-kb5002270-fullfile-x64-glb.exe" ; ChecksumType = " SHA256" ; Checksum = " 7E496530EB873146650A9E0653DE835CB2CAD9AF8D154CBD7387BB0F2297C9FC" },
            @{ DownloadUrl = " https://download.microsoft.com/download/3/f/5/3f5b1ee0-3336-45d7-b2f4-1e6af977d574/sts-subscription-kb5002271-fullfile-x64-glb.exe" ; ChecksumType = " SHA256" ; Checksum = " 247011443AC573D4F03B1622065A7350B8B3DAE04D6A5A6DC64C8270A3BE7636" }
        )
    },
    {
        Label = " 23H1" ,
        Packages = @(
            @{ DownloadUrl = " https://download.microsoft.com/download/c/6/a/c6a17105-3d86-42ad-888d-49b22383bfa1/uber-subscription-kb5002355-fullfile-x64-glb.exe" }
        )
    },
    @{
        Label = " Latest" ; 
        Packages = @(
            @{ DownloadUrl = " https://download.microsoft.com/download/d/6/d/d6dcc9e7-744e-43e1-b4be-206a6acd4f88/sts-subscription-kb5002331-fullfile-x64-glb.exe" },
            @{ DownloadUrl = " https://download.microsoft.com/download/d/3/5/d354b6e2-fa16-48e0-b3f8-423f7ca279a0/wssloc-subscription-kb5002326-fullfile-x64-glb.exe" }
        )
    }
)

$outputPath = " C:\Packages\Plugins\Microsoft.Powershell.DSC\2.83.5\DSCWork\ConfigureSPSE.0\ConfigureSPVM"
ConfigureSPVM -DomainAdminCreds $WEDomainAdminCreds -SPSetupCreds $WESPSetupCreds -SPFarmCreds $WESPFarmCreds -SPSvcCreds $WESPSvcCreds -SPAppPoolCreds $WESPAppPoolCreds -SPADDirSyncCreds $WESPADDirSyncCreds -SPPassphraseCreds $WESPPassphraseCreds -SPSuperUserCreds $WESPSuperUserCreds -SPSuperReaderCreds $WESPSuperReaderCreds -DNSServerIP $WEDNSServerIP -DomainFQDN $WEDomainFQDN -DCServerName $WEDCServerName -SQLServerName $WESQLServerName -SQLAlias $WESQLAlias -SharePointVersion $WESharePointVersion -SharePointSitesAuthority $WESharePointSitesAuthority -SharePointCentralAdminPort $WESharePointCentralAdminPort -EnableAnalysis $WEEnableAnalysis -SharePointBits $WESharePointBits -ConfigurationData @{AllNodes=@(@{ NodeName=" localhost" ; PSDscAllowPlainTextPassword=$true })} -OutputPath $outputPath
Set-DscLocalConfigurationManager -Path $outputPath
Start-DscConfiguration -Path $outputPath -Wait -Verbose -Force

C:\WindowsAzure\Logs\Plugins\Microsoft.Powershell.DSC\2.83.5



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================