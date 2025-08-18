<#
.SYNOPSIS
    Configureadbdc

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
    We Enhanced Configureadbdc

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


configuration ConfigureADBDC
{
   [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
        [Parameter(Mandatory)]
        [String]$WEDomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$WEAdmincreds,

        [Int]$WERetryCount=20,
        [Int]$WERetryIntervalSec=30
    )

    Import-DscResource -ModuleName xActiveDirectory, xPendingReboot

    [System.Management.Automation.PSCredential ]$WEDomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdmincreds.UserName)" , $WEAdmincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
        
        xWaitForADDomain DscForestWait
        {
            DomainName = $WEDomainName
            DomainUserCredential= $WEDomainCreds
            RetryCount = $WERetryCount
            RetryIntervalSec = $WERetryIntervalSec
        }
        xADDomainController BDC
        {
            DomainName = $WEDomainName
            DomainAdministratorCredential = $WEDomainCreds
            SafemodeAdministratorPassword = $WEDomainCreds
            DatabasePath = " F:\NTDS"
            LogPath = " F:\NTDS"
            SysvolPath = " F:\SYSVOL"
            DependsOn = " [xWaitForADDomain]DscForestWait"
        }
<#
        Script UpdateDNSForwarder
        {
            SetScript =
            {
                Write-Verbose -Verbose " Getting DNS forwarding rule..."
               ;  $dnsFwdRule = Get-DnsServerForwarder -Verbose
                if ($dnsFwdRule)
                {
                    Write-Verbose -Verbose " Removing DNS forwarding rule"
                    Remove-DnsServerForwarder -IPAddress $dnsFwdRule.IPAddress -Force -Verbose
                }
                Write-Verbose -Verbose " End of UpdateDNSForwarder script..."
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = " [xADDomainController]BDC"
        }

        xPendingReboot RebootAfterPromotion {
            Name = " RebootAfterDCPromotion"
            DependsOn = " [xADDomainController]BDC"
        }

    }
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
