#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Demoazurefunctionpowershell

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Demoazurefunctionpowershell

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"; 
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
.NOTES
    General notes








; 
$WEPasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$WEPasswordProfile.Password=" Default1234"

New-AzureADUser -DisplayName " testAzFuncPSUserDisplayName" -GivenName " testAzFuncPSUserGivenName" -SurName " testAzFuncPSUsersurname" -UserPrincipalName 'testAzFuncPSUser@canadacomputing.ca' -UsageLocation 'CA' -MailNickName 'testAzFuncPSUser' -PasswordProfile $WEPasswordProfile -AccountEnabled $true



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
