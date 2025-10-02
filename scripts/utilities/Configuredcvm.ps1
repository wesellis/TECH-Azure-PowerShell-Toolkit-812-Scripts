#Requires -Version 7.4
#Requires -Modules ActiveDirectoryDsc, NetworkingDsc, CertificateDsc, DnsServerDsc, ComputerManagementDsc, AdfsDsc

<#
.SYNOPSIS
    Configure Domain Controller VM

.DESCRIPTION
    DSC configuration for domain controller VM with ADFS and SharePoint integration

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

configuration ConfigureDCVM
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$DomainFQDN,

        [Parameter(Mandatory = $true)]
        [String]$PrivateIP,

        [Parameter(Mandatory = $true)]
        [String]$SPServerName,

        [Parameter(Mandatory = $true)]
        [String]$SharePointSitesAuthority,

        [Parameter(Mandatory = $true)]
        [String]$SharePointCentralAdminPort,

        [Parameter()]
        [Boolean]$ApplyBrowserPolicies = $true,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$AdfsSvcCreds
    )

    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName CertificateDsc
    Import-DscResource -ModuleName DnsServerDsc
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName AdfsDsc

    [String]$InterfaceAlias = (Get-NetAdapter | Where-Object InterfaceDescription -Like "Microsoft Hyper-V Network Adapter*" | Select-Object -First 1).Name
    [String]$ComputerName = $env:COMPUTERNAME
    [String]$DomainNetbiosName = $DomainFQDN.Split('.')[0].ToUpper()
    [String]$AdditionalUsersPath = "OU=AdditionalUsers,DC={0},DC={1}" -f $DomainFQDN.Split('.')[0], $DomainFQDN.Split('.')[1]
    [System.Management.Automation.PSCredential]$DomainCredsNetbios = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential]$AdfsSvcCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($AdfsSvcCreds.UserName)", $AdfsSvcCreds.Password)

    [String]$SetupPath = "C:\DSC Data"
    [String]$ADFSSiteName = "adfs"
    [String]$AdfsOidcAGName = "SPS-Subscription-OIDC"
    [String]$AdfsOidcIdentifier = "fae5bd07-be63-4a64-a28c-7931a4ebf62b"
    [String]$CentralAdminUrl = "http://{0}:{1}/" -f $SPServerName, $SharePointCentralAdminPort
    [String]$RootSiteDefaultZone = "http://{0}/" -f $SharePointSitesAuthority
    [String]$RootSiteIntranetZone = "https://{0}.{1}/" -f $SharePointSitesAuthority, $DomainFQDN

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        WindowsFeature DnsTools
        {
            Name = "RSAT-DNS-Server"
            Ensure = "Present"
        }

        WindowsFeature ADFS
        {
            Name = "ADFS-Federation"
            Ensure = "Present"
        }

        DnsServerAddress DnsServerAddress
        {
            Address        = $PrivateIP, '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            Validate       = $false
        }

        Computer Rename
        {
            Name = $ComputerName
        }
    }
}

function Get-NetBIOSName {
    param(
        [string]$DomainFQDN
    )

    if ($DomainFQDN.Contains('.')) {
        $length = $DomainFQDN.IndexOf('.')
        if ($length -ge 16) {
            $length = 15
        }
        return $DomainFQDN.Substring(0, $length).ToUpper()
    }
    else {
        if ($DomainFQDN.Length -gt 15) {
            return $DomainFQDN.Substring(0, 15).ToUpper()
        }
        else {
            return $DomainFQDN.ToUpper()
        }
    }
}