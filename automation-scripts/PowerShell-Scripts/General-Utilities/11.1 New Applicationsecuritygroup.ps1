#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    11.1 New Applicationsecuritygroup

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
    We Enhanced 11.1 New Applicationsecuritygroup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$newAzApplicationSecurityGroupSplat = @{
New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat


$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }
; 
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " MyResourceGroup"
    Name = " MyApplicationSecurityGroup"
    Location = " West US"
    Tag = '' 
}

New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
