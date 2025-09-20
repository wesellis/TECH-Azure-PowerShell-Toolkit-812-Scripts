#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Check Azadsinglesignon

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Install-Module -Name AzureAD -Force
Connect-AzureAD
$ssoPolicy = Get-AzureADPolicy -Id "AuthenticationPolicy"
if ($ssoPolicy.AuthenticationType -eq "CloudSSO" ) {
    Write-Host "Single sign-on is enabled for the domain."
} else {
    Write-Host "Single sign-on is not enabled for the domain."
}\n

