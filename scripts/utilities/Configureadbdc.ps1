#Requires -Version 7.4
#Requires -Modules xActiveDirectory, xPendingReboot

<#
.SYNOPSIS
    Configure Active Directory Backup Domain Controller

.DESCRIPTION
    DSC configuration for setting up an Active Directory Backup Domain Controller

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

configuration ConfigureADBDC
{
    param(
        [Parameter(Mandatory = $true)]
        [String]$DomainName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    )

    Import-DscResource -ModuleName xActiveDirectory, xPendingReboot

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
        }

        xADDomainController BDC
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot RebootAfterPromotion
        {
            Name = "RebootAfterDCPromotion"
            DependsOn = "[xADDomainController]BDC"
        }
    }
}