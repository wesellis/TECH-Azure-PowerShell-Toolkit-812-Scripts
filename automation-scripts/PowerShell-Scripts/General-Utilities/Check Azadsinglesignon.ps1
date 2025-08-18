<#
.SYNOPSIS
    We Enhanced Check Azadsinglesignon

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

Install-Module -Name AzureAD -Force


Connect-AzureAD

; 
$ssoPolicy = Get-AzureADPolicy -Id " AuthenticationPolicy"


if ($ssoPolicy.AuthenticationType -eq " CloudSSO") {
    Write-WELog " Single sign-on is enabled for the domain." " INFO"
} else {
    Write-WELog " Single sign-on is not enabled for the domain." " INFO"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================