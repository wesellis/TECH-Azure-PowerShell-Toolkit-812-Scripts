<#
.SYNOPSIS
    We Enhanced Import Azpfxcertazkeyvault

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


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)


    

Certificate   : [Subject]
                  CN=rds.miaonline.org

                [Issuer]
                  CN=ZeroSSL RSA Domain Secure Site CA, O=ZeroSSL, C=AT

                [Serial Number]
                  0EEDFD89DEB321E2F5C42A64DD40B3BF

                [Not Before]
                  2020-11-26 6:00:00 PM

                [Not After]
                  2021-11-27 5:59:59 PM

                [Thumbprint]
                  8352BDD3F57CD6EC28CF1DC09C164B1571CD23E8

KeyId         : https://miaqbrdskv1.vault.azure.net:443/keys/MIASSLRDSCERT1/d7e7f54793954fadbe33094ab8bd79da
SecretId      : https://miaqbrdskv1.vault.azure.net:443/secrets/MIASSLRDSCERT1/d7e7f54793954fadbe33094ab8bd79da
Thumbprint    : 8352BDD3F57CD6EC28CF1DC09C164B1571CD23E8
RecoveryLevel : Recoverable+Purgeable
Enabled       : True
Expires       : 2021-11-27 11:59:59 PM
NotBefore     : 2020-11-27 12:00:00 AM
Created       : 2020-11-27 5:35:58 PM
Updated       : 2020-11-27 5:35:58 PM
Tags          :
VaultName     : miaqbrdskv1
Name          : MIASSLRDSCERT1
Version       : d7e7f54793954fadbe33094ab8bd79da
Id            : https://miaqbrdskv1.vault.azure.net:443/certificates/MIASSLRDSCERT1/d7e7f54793954fadbe33094ab8bd79da
.NOTES
    General notes


Connect-AzAccount

$WECertPassword = Read-Host -AsSecureString -Prompt 'Enter your cert password'; 
$WEPassword = ConvertTo-SecureString -String $WECertPassword -AsPlainText -Force
Import-AzKeyVaultCertificate -VaultName " MIAQBRDSKV1" -Name " MIASSLRDSCERT1" -FilePath " C:\Users\Abdullah.Ollivierre\AzureRepos2\Git-HubRepositry\Functions\Export-CertToPFX\PlaceZeroSSLCertfileshere\rds.miaonline.org\cert.pfx" -Password $WEPassword


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================