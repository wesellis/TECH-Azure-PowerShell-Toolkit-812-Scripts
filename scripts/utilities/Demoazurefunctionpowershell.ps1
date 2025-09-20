#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Demoazurefunctionpowershell

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    General notes
$PasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password="Default1234"
New-AzureADUser -DisplayName " testAzFuncPSUserDisplayName" -GivenName " testAzFuncPSUserGivenName" -SurName " testAzFuncPSUsersurname" -UserPrincipalName 'testAzFuncPSUser@canadacomputing.ca' -UsageLocation 'CA' -MailNickName 'testAzFuncPSUser' -PasswordProfile $PasswordProfile -AccountEnabled $true


