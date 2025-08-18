<#
.SYNOPSIS
    We Enhanced Configuredcvm

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

﻿configuration ConfigureDCVM
{
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)] [String]$WEDomainFQDN,
        [Parameter(Mandatory)] [String]$WEPrivateIP,
        [Parameter(Mandatory)] [String]$WESPServerName,
        [Parameter(Mandatory)] [String]$WESharePointSitesAuthority,
        [Parameter(Mandatory)] [String]$WESharePointCentralAdminPort,
        [Parameter ()] [Boolean]$WEApplyBrowserPolicies = $true,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WEAdmincreds,
        [Parameter(Mandatory)] [System.Management.Automation.PSCredential]$WEAdfsSvcCreds
    )

    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion 6.6.2
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 9.0.0
    Import-DscResource -ModuleName ActiveDirectoryCSDsc -ModuleVersion 5.0.0
    Import-DscResource -ModuleName CertificateDsc -ModuleVersion 6.0.0
    Import-DscResource -ModuleName DnsServerDsc -ModuleVersion 3.0.0
    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 10.0.0 # Custom
    Import-DscResource -ModuleName AdfsDsc -ModuleVersion 1.4.0

    # Init
    [String] $WEInterfaceAlias = (Get-NetAdapter| Where-Object InterfaceDescription -Like "Microsoft Hyper-V Network Adapter*" | Select-Object -First 1).Name
    [String] $WEComputerName = Get-Content env:computername
    [String] $WEDomainNetbiosName = (Get-NetBIOSName -DomainFQDN $WEDomainFQDN)
    [String] $WEAdditionalUsersPath = " OU=AdditionalUsers,DC={0},DC={1}" -f $WEDomainFQDN.Split('.')[0], $WEDomainFQDN.Split('.')[1]

    # Format credentials to be qualified by domain name: " domain\username"
    [System.Management.Automation.PSCredential] $WEDomainCredsNetbios = New-Object System.Management.Automation.PSCredential (" ${DomainNetbiosName}\$($WEAdmincreds.UserName)", $WEAdmincreds.Password)
    [System.Management.Automation.PSCredential] $WEAdfsSvcCredsQualified = New-Object System.Management.Automation.PSCredential (" ${DomainNetbiosName}\$($WEAdfsSvcCreds.UserName)", $WEAdfsSvcCreds.Password)

    [String] $WESetupPath = " C:\DSC Data"

    # ADFS settings
    [String] $WEADFSSiteName = " adfs"
    [String] $WEAdfsOidcAGName = " SPS-Subscription-OIDC"
    [String] $WEAdfsOidcIdentifier = " fae5bd07-be63-4a64-a28c-7931a4ebf62b"
    
    # SharePoint settings
    [String] $centralAdminUrl = " http://{0}:{1}/" -f $WESPServerName, $WESharePointCentralAdminPort
    [String] $rootSiteDefaultZone = " http://{0}/" -f $WESharePointSitesAuthority
    [String] $rootSiteIntranetZone = " https://{0}.{1}/" -f $WESharePointSitesAuthority, $WEDomainFQDN
    [String] $WEAppDomainFQDN = " {0}{1}.{2}" -f $WEDomainFQDN.Split('.')[0], " Apps", $WEDomainFQDN.Split('.')[1]
    [String] $WEAppDomainIntranetFQDN = " {0}{1}.{2}" -f $WEDomainFQDN.Split('.')[0], " Apps-Intranet", $WEDomainFQDN.Split('.')[1]

    # Browser policies
    # Edge
    [System.Object[]];  $WEEdgePolicies = @(
        @{
            policyValueName        = " HideFirstRunExperience";
            policyCanBeRecommended = $false;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = " TrackingPrevention";
            policyCanBeRecommended = $false;
            policyValueValue       = 3;
        },
        @{
            policyValueName        = " AdsTransparencyEnabled";
            policyCanBeRecommended = $false;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = " BingAdsSuppression";
            policyCanBeRecommended = $false;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = " AdsSettingForIntrusiveAdsSites";
            policyCanBeRecommended = $false;
            policyValueValue       = 2;
        },
        @{
            policyValueName        = " AskBeforeCloseEnabled";
            policyCanBeRecommended = $true;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = " BlockThirdPartyCookies";
            policyCanBeRecommended = $true;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = " ConfigureDoNotTrack";
            policyCanBeRecommended = $false;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = " DiagnosticData";
            policyCanBeRecommended = $false;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = " HubsSidebarEnabled";
            policyCanBeRecommended = $true;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = " HomepageIsNewTabPage";
            policyCanBeRecommended = $true;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = " HomepageLocation";
            policyCanBeRecommended = $true;
            policyValueValue       = " edge://newtab";
        },
        @{
            policyValueName        = " ShowHomeButton";
            policyCanBeRecommended = $true;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = " NewTabPageLocation";
            policyCanBeRecommended = $true;
            policyValueValue       = " about://blank";
        },
        @{
            policyValueName        = " NewTabPageQuickLinksEnabled";
            policyCanBeRecommended = $false;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = " NewTabPageContentEnabled";
            policyCanBeRecommended = $false;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = " NewTabPageAllowedBackgroundTypes";
            policyCanBeRecommended = $false;
            policyValueValue       = 3;
        },
        @{
            policyValueName        = " NewTabPageAppLauncherEnabled";
            policyCanBeRecommended = $false;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = " ManagedFavorites";
            policyCanBeRecommended = $false;
            policyValueValue       = " [{ "" toplevel_name"" : "" SharePoint"" }, { "" name"" : "" Central administration"" , "" url"" : "" $centralAdminUrl"" }, { "" name"" : "" Root site - Default zone"" , "" url"" : "" $rootSiteDefaultZone"" }, { "" name"" : "" Root site - Intranet zone"" , "" url"" : "" $rootSiteIntranetZone"" }]" ;
        },
        @{
            policyValueName        = "NewTabPageManagedQuickLinks" ;
            policyCanBeRecommended = $true;
            policyValueValue       = "[{"" pinned"" : true, "" title"" : "" Central administration"" , "" url"" : "" $centralAdminUrl"" }, { "" pinned"" : true, "" title"" : "" Root site - Default zone"" , "" url"" : "" $rootSiteDefaultZone"" }, { "" pinned"" : true, "" title"" : "" Root site - Intranet zone"" , "" url"" : "" $rootSiteIntranetZone"" }]" ;
        }
    )

    [System.Object[]] $WEChromePolicies = @(
        @{
            policyValueName        = "MetricsReportingEnabled" ;
            policyCanBeRecommended = $true;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = "PromotionalTabsEnabled" ;
            policyCanBeRecommended = $false;
            policyValueValue       = 0;
        },
        @{
            policyValueName        = "AdsSettingForIntrusiveAdsSites" ;
            policyCanBeRecommended = $false;
            policyValueValue       = 2;
        },
        @{
            policyValueName        = "BlockThirdPartyCookies" ;
            policyCanBeRecommended = $true;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = "HomepageIsNewTabPage" ;
            policyCanBeRecommended = $true;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = "HomepageLocation" ;
            policyCanBeRecommended = $true;
            policyValueValue       = "edge://newtab" ;
        },
        @{
            policyValueName        = "ShowHomeButton" ;
            policyCanBeRecommended = $true;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = "NewTabPageLocation" ;
            policyCanBeRecommended = $false;
            policyValueValue       = "about://blank" ;
        },
        @{
            policyValueName        = "BookmarkBarEnabled" ;
            policyCanBeRecommended = $true;
            policyValueValue       = 1;
        },
        @{
            policyValueName        = "ManagedBookmarks" ;
            policyCanBeRecommended = $false;
            policyValueValue       = "[{ "" toplevel_name"" : "" SharePoint"" }, { "" name"" : "" Central administration"" , "" url"" : "" $centralAdminUrl"" }, { "" name"" : "" Root site - Default zone"" , "" url"" : "" $rootSiteDefaultZone"" }, { "" name"" : "" Root site - Intranet zone"" , "" url"" : "" $rootSiteIntranetZone"" }]" ;
        }
    )

    [System.Object[]] $WEAdditionalUsers = @(
        @{
            DisplayName = "Marie Berthelette" ;
            UserName    = "MarieB"
        },
        @{
            DisplayName = " Camille Cartier";
            UserName    = " CamilleC"
        },
        @{
            DisplayName = " Elisabeth Arcouet";
            UserName    = " ElisabethA"
        },
        @{
            DisplayName = " Ana Bowman";
            UserName    = " AnaB"
        },
        @{
            DisplayName = " Olivia Wilson";
            UserName    = " OliviaW"
        }
    )

    Node localhost
    {
        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        # Fix emerging issue " WinRM cannot process the request. The following error with errorcode 0x80090350" while Windows Azure Guest Agent service initiates using https://stackoverflow.com/a/74015954/8669078
        Script SetWindowsAzureGuestAgentDepndencyOnDNS {
            GetScript  = { }
            TestScript = { return $false }
            SetScript  = { Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WindowsAzureGuestAgent' -Name " DependOnService" -Type MultiString -Value " DNS" }
        }

        #**********************************************************
        # Create AD domain
        #**********************************************************
        # Install AD FS early (before reboot) to workaround error below on resource AdfsApplicationGroup:
        # " System.InvalidOperationException: The test script threw an error. ---> System.IO.FileNotFoundException: Could not load file or assembly 'Microsoft.IdentityServer.Diagnostics, Version=10.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35' or one of its dependencie"
        WindowsFeature AddADFS {
            Name = " ADFS-Federation"; Ensure = " Present"; 
        }
        WindowsFeature AddADDS {
            Name = " AD-Domain-Services"; Ensure = " Present" 
        }
        WindowsFeature AddDNS {
            Name = " DNS"; Ensure = " Present" 
        }
        DnsServerAddress SetDNS {
            Address = '127.0.0.1' ; InterfaceAlias = $WEInterfaceAlias; AddressFamily = 'IPv4' 
        }
        # IPAddress NewIPv4Address
        # {
        #     IPAddress = '10.1.1.4'; InterfaceAlias = $WEInterfaceAlias; AddressFamily  = 'IPV4'
        # }

        ADDomain CreateADForest {
            DomainName                    = $WEDomainFQDN
            Credential                    = $WEDomainCredsNetbios
            SafemodeAdministratorPassword = $WEDomainCredsNetbios
            DatabasePath                  = " C:\NTDS"
            LogPath                       = " C:\NTDS"
            SysvolPath                    = " C:\SYSVOL"
            DependsOn                     = " [DnsServerAddress]SetDNS", " [WindowsFeature]AddADDS"
        }

        PendingReboot RebootOnSignalFromCreateADForest {
            Name      = " RebootOnSignalFromCreateADForest"
            DependsOn = " [ADDomain]CreateADForest"
        }

        WaitForADDomain WaitForDCReady {
            DomainName              = $WEDomainFQDN
            WaitTimeout             = 300
            RestartCount            = 3
            Credential              = $WEDomainCredsNetbios
            WaitForValidCredentials = $true
            DependsOn               = " [PendingReboot]RebootOnSignalFromCreateADForest"
        }

        if ($true -eq $WEApplyBrowserPolicies) {
            # Set browser policies asap, so that computers that join domain get them immediately, and  it runs very quickly (<5 secs)
            # Edge - https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies
            Script ConfigureEdgePolicies {
                SetScript  = {
                    $domain = Get-ADDomain -Current LocalComputer
                    $registryKey = " HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge"
                    $policies = $using:EdgePolicies
                    $gpo = New-GPO -name " Edge_browser"
                    New-GPLink -Guid $gpo.Id -Target $domain.DistinguishedName -order 1

                    foreach ($policy in $policies) {
                        $key = $registryKey
                        if ($true -eq $policy.policyCanBeRecommended) { $key = $key + " \Recommended" }
                        $valueType = if ($policy.policyValueValue -is [int]) { " DWORD" } else { " STRING" }
                        Set-GPRegistryValue -Guid $gpo.Id -key $key -ValueName $policy.policyValueName -Type $valueType -value $policy.policyValueValue
                    }
                }
                GetScript  = { return @{ " Result" = " false" } }
                TestScript = {
                    $policy = Get-GPO -name " Edge_browser" -ErrorAction SilentlyContinue
                    if ($null -eq $policy) {
                        return $false
                    }
                    else {
                        return $true
                    }
                }
            }

            # Chrome - https://chromeenterprise.google/intl/en_us/policies/
            Script ConfigureChromePolicies {
                SetScript  = {
                    $domain = Get-ADDomain -Current LocalComputer
                    $registryKey = " HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome"
                    $policies = $using:ChromePolicies
                    $gpo = New-GPO -name " Chrome_browser"
                    New-GPLink -Guid $gpo.Id -Target $domain.DistinguishedName -order 1

                    foreach ($policy in $policies) {
                        $key = $registryKey
                        if ($true -eq $policy.policyCanBeRecommended) { $key = $key + " \Recommended" }
                        $valueType = if ($policy.policyValueValue -is [int]) { " DWORD" } else { " STRING" }
                        Set-GPRegistryValue -Guid $gpo.Id -key $key -ValueName $policy.policyValueName -Type $valueType -value $policy.policyValueValue
                    }
                }
                GetScript  = { return @{ " Result" = " false" } }
                TestScript = {
                   ;  $policy = Get-GPO -name " Chrome_browser" -ErrorAction SilentlyContinue
                    if ($null -eq $policy) {
                        return $false
                    }
                    else {
                        return $true
                    }
                }
            }
        }
        
        #**********************************************************
        # Configuration needed by SharePoint farm
        #**********************************************************
        DnsServerPrimaryZone CreateAppsDnsZone {
            Name      = $WEAppDomainFQDN
            Ensure    = " Present"
            DependsOn = " [WaitForADDomain]WaitForDCReady"
        }

        DnsServerPrimaryZone CreateAppsIntranetDnsZone {
            Name      = $WEAppDomainIntranetFQDN
            Ensure    = " Present"
            DependsOn = " [WaitForADDomain]WaitForDCReady"
        }

        ADUser SetEmailOfDomainAdmin {
            DomainName           = $WEDomainFQDN
            UserName             = $WEAdmincreds.UserName
            EmailAddress         = " $($WEAdmincreds.UserName)@$WEDomainFQDN"
            UserPrincipalName    = " $($WEAdmincreds.UserName)@$WEDomainFQDN"
            PasswordNeverExpires = $true
            Ensure               = " Present"
            DependsOn            = " [WaitForADDomain]WaitForDCReady"
        }

        #**********************************************************
        # Configure AD CS
        #**********************************************************
        WindowsFeature AddADCSFeature {
            Name = " ADCS-Cert-Authority"; Ensure = " Present"; DependsOn = " [WaitForADDomain]WaitForDCReady" 
        }
        
        ADCSCertificationAuthority CreateADCSAuthority {
            IsSingleInstance = " Yes"
            CAType           = " EnterpriseRootCA"
            Ensure           = " Present"
            Credential       = $WEDomainCredsNetbios
            DependsOn        = " [WindowsFeature]AddADCSFeature"
        }

        WaitForCertificateServices WaitAfterADCSProvisioning {
            CAServerFQDN         = " $WEComputerName.$WEDomainFQDN"
            CARootName           = " $WEDomainNetbiosName-$WEComputerName-CA"
            DependsOn            = '[ADCSCertificationAuthority]CreateADCSAuthority'
            PsDscRunAsCredential = $WEDomainCredsNetbios
        }

        CertReq GenerateLDAPSCertificate {
            CARootName          = " $WEDomainNetbiosName-$WEComputerName-CA"
            CAServerFQDN        = " $WEComputerName.$WEDomainFQDN"
            Subject             = " CN=$WEComputerName.$WEDomainFQDN"
            FriendlyName        = " LDAPS certificate for $WEComputerName.$WEDomainFQDN"
            KeyLength           = '2048'
            Exportable          = $true
            ProviderName        = '" Microsoft RSA SChannel Cryptographic Provider"'
            OID                 = '1.3.6.1.5.5.7.3.1'
            KeyUsage            = '0xa0'
            CertificateTemplate = 'WebServer'
            AutoRenew           = $true
            Credential          = $WEDomainCredsNetbios
            DependsOn           = '[WaitForCertificateServices]WaitAfterADCSProvisioning'
        }

        #**********************************************************
        # Configure AD FS
        #**********************************************************
        CertReq GenerateADFSSiteCertificate {
            CARootName          = " $WEDomainNetbiosName-$WEComputerName-CA"
            CAServerFQDN        = " $WEComputerName.$WEDomainFQDN"
            Subject             = " $WEADFSSiteName.$WEDomainFQDN"
            FriendlyName        = " $WEADFSSiteName.$WEDomainFQDN site certificate"
            KeyLength           = '2048'
            Exportable          = $true
            ProviderName        = '" Microsoft RSA SChannel Cryptographic Provider"'
            OID                 = '1.3.6.1.5.5.7.3.1'
            KeyUsage            = '0xa0'
            CertificateTemplate = 'WebServer'
            AutoRenew           = $true
            SubjectAltName      = " dns=certauth.$WEADFSSiteName.$WEDomainFQDN&dns=$WEADFSSiteName.$WEDomainFQDN&dns=enterpriseregistration.$WEDomainFQDN"
            Credential          = $WEDomainCredsNetbios
            DependsOn           = '[WaitForCertificateServices]WaitAfterADCSProvisioning'
        }

        CertReq GenerateADFSSigningCertificate {
            CARootName          = " $WEDomainNetbiosName-$WEComputerName-CA"
            CAServerFQDN        = " $WEComputerName.$WEDomainFQDN"
            Subject             = " $WEADFSSiteName.Signing"
            FriendlyName        = " $WEADFSSiteName Signing"
            KeyLength           = '2048'
            Exportable          = $true
            ProviderName        = '" Microsoft RSA SChannel Cryptographic Provider"'
            OID                 = '1.3.6.1.5.5.7.3.1'
            KeyUsage            = '0xa0'
            CertificateTemplate = 'WebServer'
            AutoRenew           = $true
            Credential          = $WEDomainCredsNetbios
            DependsOn           = '[WaitForCertificateServices]WaitAfterADCSProvisioning'
        }

        CertReq GenerateADFSDecryptionCertificate {
            CARootName          = " $WEDomainNetbiosName-$WEComputerName-CA"
            CAServerFQDN        = " $WEComputerName.$WEDomainFQDN"
            Subject             = " $WEADFSSiteName.Decryption"
            FriendlyName        = " $WEADFSSiteName Decryption"
            KeyLength           = '2048'
            Exportable          = $true
            ProviderName        = '" Microsoft RSA SChannel Cryptographic Provider"'
            OID                 = '1.3.6.1.5.5.7.3.1'
            KeyUsage            = '0xa0'
            CertificateTemplate = 'WebServer'
            AutoRenew           = $true
            Credential          = $WEDomainCredsNetbios
            DependsOn           = '[WaitForCertificateServices]WaitAfterADCSProvisioning'
        }

        Script ExportCertificates {
            SetScript  = 
            {
                $destinationPath = $using:SetupPath
                $adfsSigningCertName = " ADFS Signing.cer"
                $adfsSigningIssuerCertName = " ADFS Signing issuer.cer"
                Write-Verbose -Verbose -Message " Exporting public key of ADFS signing / signing issuer certificates..."
                New-Item $destinationPath -Type directory -ErrorAction SilentlyContinue
               ;  $signingCert = Get-ChildItem -Path " cert:\LocalMachine\My\" -DnsName " $using:ADFSSiteName.Signing"
                $signingCert | Export-Certificate -FilePath ([System.IO.Path]::Combine($destinationPath, $adfsSigningCertName))
                Get-ChildItem -Path " cert:\LocalMachine\Root\" | Where-Object { $_.Subject -eq $signingCert.Issuer } | Select-Object -First 1 | Export-Certificate -FilePath ([System.IO.Path]::Combine($destinationPath, $adfsSigningIssuerCertName))
                Write-Verbose -Verbose -Message " Public key of ADFS signing / signing issuer certificates successfully exported"
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
            DependsOn  = " [CertReq]GenerateADFSSiteCertificate", " [CertReq]GenerateADFSSigningCertificate", " [CertReq]GenerateADFSDecryptionCertificate"
        }

        ADUser CreateAdfsSvcAccount {
            DomainName             = $WEDomainFQDN
            UserName               = $WEAdfsSvcCreds.UserName
            UserPrincipalName      = " $($WEAdfsSvcCreds.UserName)@$WEDomainFQDN"
            Password               = $WEAdfsSvcCreds
            PasswordAuthentication = 'Negotiate'
            PasswordNeverExpires   = $true
            Ensure                 = " Present"
            DependsOn              = " [CertReq]GenerateADFSSiteCertificate", " [CertReq]GenerateADFSSigningCertificate", " [CertReq]GenerateADFSDecryptionCertificate"
        }

        # https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/deployment/configure-corporate-dns-for-the-federation-service-and-drs
        DnsRecordCname AddADFSDevideRegistrationAlias {
            Name          = " enterpriseregistration"
            ZoneName      = $WEDomainFQDN
            HostNameAlias = " $WEComputerName.$WEDomainFQDN"
            Ensure        = " Present"
            DependsOn     = " [WaitForADDomain]WaitForDCReady"
        }

        AdfsFarm CreateADFSFarm {
            FederationServiceName        = " $WEADFSSiteName.$WEDomainFQDN"
            FederationServiceDisplayName = " $WEADFSSiteName.$WEDomainFQDN"
            CertificateDnsName           = " $WEADFSSiteName.$WEDomainFQDN"
            SigningCertificateDnsName    = " $WEADFSSiteName.Signing"
            DecryptionCertificateDnsName = " $WEADFSSiteName.Decryption"
            ServiceAccountCredential     = $WEAdfsSvcCredsQualified
            Credential                   = $WEDomainCredsNetbios
            DependsOn                    = " [WindowsFeature]AddADFS"
        }

        # This DNS record is tested by other VMs to join AD only after it was found
        # It is added after DSC resource AdfsFarm, because it is the last operation that triggers a reboot of the DC
        DnsRecordA AddADFSHostDNS {
            Name        = $WEADFSSiteName
            ZoneName    = $WEDomainFQDN
            IPv4Address = $WEPrivateIP
            Ensure      = " Present"
            DependsOn   = " [AdfsFarm]CreateADFSFarm"
        }

        ADFSRelyingPartyTrust CreateADFSRelyingParty {
            Name                       = $WESharePointSitesAuthority
            Identifier                 = " urn:sharepoint:$($WESharePointSitesAuthority)"
            ClaimsProviderName         = @(" Active Directory")
            WSFedEndpoint              = " https://$WESharePointSitesAuthority.$WEDomainFQDN/_trust/"
            ProtocolProfile            = " WsFed-SAML"
            AdditionalWSFedEndpoint    = @(" https://*.$WEDomainFQDN/")
            IssuanceAuthorizationRules = ' => issue(Type = " http://schemas.microsoft.com/authorization/claims/permit", value = " true");'
            IssuanceTransformRules     = @(
                MSFT_AdfsIssuanceTransformRule {
                    TemplateName   = 'LdapClaims'
                    Name           = 'Claims from Active Directory attributes'
                    AttributeStore = 'Active Directory'
                    LdapMapping    = @(
                        MSFT_AdfsLdapMapping {
                            LdapAttribute     = 'userPrincipalName'
                            OutgoingClaimType = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn'
                        }
                        MSFT_AdfsLdapMapping {
                            LdapAttribute     = 'mail'
                            OutgoingClaimType = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
                        }
                        MSFT_AdfsLdapMapping {
                            LdapAttribute     = 'tokenGroups(longDomainQualifiedName)'
                            OutgoingClaimType = 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'
                        }
                    )
                }
            )
            Ensure                     = 'Present'
            PsDscRunAsCredential       = $WEDomainCredsNetbios
            DependsOn                  = " [AdfsFarm]CreateADFSFarm"
        }

        AdfsApplicationGroup OidcGroup {
            Name                 = $WEAdfsOidcAGName
            Description          = " OIDC for SharePoint Subscription"
            PsDscRunAsCredential = $WEDomainCredsNetbios
            DependsOn            = " [AdfsFarm]CreateADFSFarm"
        }

        AdfsNativeClientApplication OidcNativeApp {
            Name                       = " $WEAdfsOidcAGName - Native application"
            ApplicationGroupIdentifier = $WEAdfsOidcAGName
            Identifier                 = $WEAdfsOidcIdentifier
            RedirectUri                = " https://*.$WEDomainFQDN/"
            DependsOn                  = " [AdfsApplicationGroup]OidcGroup"
        }

        AdfsWebApiApplication OidcWebApiApp {
            Name                          = " $WEAdfsOidcAGName - Web API"
            ApplicationGroupIdentifier    = $WEAdfsOidcAGName
            Identifier                    = $WEAdfsOidcIdentifier
            AccessControlPolicyName       = " Permit everyone"
            AlwaysRequireAuthentication   = $false
            AllowedClientTypes            = " Public", " Confidential"
            IssueOAuthRefreshTokensTo     = " AllDevices"
            NotBeforeSkew                 = 0
            RefreshTokenProtectionEnabled = $true
            RequestMFAFromClaimsProviders = $false
            TokenLifetime                 = 0
            IssuanceTransformRules        = @(
                MSFT_AdfsIssuanceTransformRule {
                    TemplateName   = 'LdapClaims'
                    Name           = 'Claims from Active Directory attributes'
                    AttributeStore = 'Active Directory'
                    LdapMapping    = @(
                        MSFT_AdfsLdapMapping {
                            LdapAttribute     = 'userPrincipalName'
                            OutgoingClaimType = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn'
                        }
                        MSFT_AdfsLdapMapping {
                            LdapAttribute     = 'mail'
                            OutgoingClaimType = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
                        }
                        MSFT_AdfsLdapMapping {
                            LdapAttribute     = 'tokenGroups(longDomainQualifiedName)'
                            OutgoingClaimType = 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'
                        }
                    )
                }
                MSFT_AdfsIssuanceTransformRule {
                    TemplateName = " CustomClaims"
                    Name         = " nbf"
                    CustomRule   = 'c:[Type == " http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname"] 
=> issue(Type = " nbf", Value = " 0");'
                }
            )
            DependsOn                     = " [AdfsApplicationGroup]OidcGroup"
        }

        AdfsApplicationPermission OidcWebApiAppPermission {
            ClientRoleIdentifier = $WEAdfsOidcIdentifier
            ServerRoleIdentifier = $WEAdfsOidcIdentifier
            ScopeNames           = " openid"
            DependsOn            = " [AdfsNativeClientApplication]OidcNativeApp", " [AdfsWebApiApplication]OidcWebApiApp"
        }

        WindowsFeature AddADTools {
            Name = " RSAT-AD-Tools"; Ensure = " Present"; 
        }        
        WindowsFeature AddDnsTools {
            Name = " RSAT-DNS-Server"; Ensure = " Present"; 
        }
        WindowsFeature AddADLDS {
            Name = " RSAT-ADLDS"; Ensure = " Present"; 
        }
        WindowsFeature AddADCSManagementTools {
            Name = " RSAT-ADCS-Mgmt"; Ensure = " Present"; 
        }

        Script EnableFileSharing {
            GetScript  = { }
            TestScript = { return $null -ne (Get-NetFirewallRule -DisplayGroup " File And Printer Sharing" -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.Profile -eq " Domain" }) }
            SetScript  = { Set-NetFirewallRule -DisplayGroup " File And Printer Sharing" -Enabled True -Profile Domain }
        }

        Script EnableRemoteEventViewerConnection {
            GetScript  = { }
            TestScript = { return $null -ne (Get-NetFirewallRule -DisplayGroup " Remote Event Log Management" -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.Profile -eq " Domain" }) }
            SetScript  = { Set-NetFirewallRule -DisplayGroup " Remote Event Log Management" -Enabled True -Profile Any }
        }

        #******************************************************************
        # Set insecure LDAP configurations from default 1 to 2 to avoid elevation of priviledge vulnerability on AD domain controller
        # Mitigate https://msrc.microsoft.com/update-guide/vulnerability/CVE-2017-8563 using https://support.microsoft.com/en-us/topic/use-the-ldapenforcechannelbinding-registry-entry-to-make-ldap-authentication-over-ssl-tls-more-secure-e9ecfa27-5e57-8519-6ba3-d2c06b21812e
        #******************************************************************
        Script EnforceLdapAuthOverTls {
            SetScript  = {
                $domain = Get-ADDomain -Current LocalComputer
                $key = " HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
                $gpo = New-GPO -name " EnforceLdapAuthOverTls"
                New-GPLink -Guid $gpo.Id -Target $domain.DomainControllersContainer -order 1
                Set-GPRegistryValue -Guid $gpo.Id -key $key -ValueName " LdapEnforceChannelBinding" -Type DWORD -value 2
                Set-GPRegistryValue -Guid $gpo.Id -key $key -ValueName " ldapserverintegrity" -Type DWORD -value 2
            }
            GetScript  = { return @{ " Result" = " false" } }
            TestScript = {
                $policy = Get-GPO -name " EnforceLdapAuthOverTls" -ErrorAction SilentlyContinue
                if ($null -eq $policy) {
                    return $false
                }
                else {
                    return $true
                }
            }
        }

        ADOrganizationalUnit AdditionalUsersOU {
            Name                            = $WEAdditionalUsersPath.Split(',')[0].Substring(3)
            Path                            = $WEAdditionalUsersPath.Substring($WEAdditionalUsersPath.IndexOf(',') + 1)
            ProtectedFromAccidentalDeletion = $false
            Ensure                          = 'Present'
            DependsOn                       = " [WaitForADDomain]WaitForDCReady"
        }

        foreach ($WEAdditionalUser in $WEAdditionalUsers) {
            ADUser " ExtraUser_$($WEAdditionalUser.UserName)" {
                DomainName           = $WEDomainFQDN
                Path                 = $WEAdditionalUsersPath
                UserName             = $WEAdditionalUser.UserName
                EmailAddress         = " $($WEAdditionalUser.UserName)@$WEDomainFQDN"
                UserPrincipalName    = " $($WEAdditionalUser.UserName)@$WEDomainFQDN"
                DisplayName          = $WEAdditionalUser.DisplayName
                GivenName            = $WEAdditionalUser.DisplayName.Split(' ')[0]
                Surname              = $WEAdditionalUser.DisplayName.Split(' ')[1]
                PasswordNeverExpires = $true
                Password             = $WEAdfsSvcCreds
                Ensure               = " Present"
                DependsOn            = " [ADOrganizationalUnit]AdditionalUsersOU"
            }
        }
    }
}

function WE-Get-NetBIOSName {
    [OutputType([string])]
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
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


Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name xAdcsDeployment
Install-Module -Name xCertificate
Install-Module -Name xPSDesiredStateConfiguration
Install-Module -Name xCredSSP
Install-Module -Name xWebAdministration
Install-Module -Name xDisk
Install-Module -Name xNetworking

help ConfigureDCVM

$password = ConvertTo-SecureString -String " mytopsecurepassword" -AsPlainText -Force
$WEAdmincreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " yvand", $password
$WEAdfsSvcCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList " adfssvc", $password
$WEDomainFQDN = " contoso.local"
$WEPrivateIP = " 10.1.1.4"
$WESPServerName = " SP"
$WESharePointSitesAuthority = " spsites"
$WESharePointCentralAdminPort = 5000
; 
$outputPath = " C:\Packages\Plugins\Microsoft.Powershell.DSC\2.83.5\DSCWork\ConfigureDCVM.0\ConfigureDCVM"
ConfigureDCVM -Admincreds $WEAdmincreds -AdfsSvcCreds $WEAdfsSvcCreds -DomainFQDN $WEDomainFQDN -PrivateIP $WEPrivateIP -SPServerName $WESPServerName -SharePointSitesAuthority $WESharePointSitesAuthority -SharePointCentralAdminPort $WESharePointCentralAdminPort -ConfigurationData @{AllNodes=@(@{ NodeName=" localhost"; PSDscAllowPlainTextPassword=$true })} -OutputPath $outputPath
Set-DscLocalConfigurationManager -Path $outputPath
Start-DscConfiguration -Path $outputPath -Wait -Verbose -Force

C:\WindowsAzure\Logs\Plugins\Microsoft.Powershell.DSC\2.83.5


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
