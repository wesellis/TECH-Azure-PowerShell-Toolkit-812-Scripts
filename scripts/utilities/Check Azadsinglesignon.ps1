#Requires -Version 7.4
#Requires -Modules Az.Resources, AzureAD

<#
.SYNOPSIS
    Check Azure AD Single Sign-On configuration

.DESCRIPTION
    Checks if Single Sign-On is enabled for Azure AD domain and displays the current SSO status

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    Write-Verbose "Installing and importing AzureAD module"
    Install-Module -Name AzureAD -Force -Scope CurrentUser

    Write-Verbose "Connecting to Azure AD"
    Connect-AzureAD

    Write-Verbose "Retrieving SSO policy configuration"
    $SsoPolicy = Get-AzureADPolicy -Id "AuthenticationPolicy"

    if ($SsoPolicy.AuthenticationType -eq "CloudSSO") {
        Write-Output "Single sign-on is enabled for the domain."
    } else {
        Write-Output "Single sign-on is not enabled for the domain."
    }
}
catch {
    Write-Error "Failed to check Azure AD SSO configuration: $($_.Exception.Message)"
    throw
}