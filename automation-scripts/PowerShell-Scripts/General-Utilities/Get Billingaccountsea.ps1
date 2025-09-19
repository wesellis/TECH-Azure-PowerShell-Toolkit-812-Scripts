#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Get Billingaccountsea

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
    We Enhanced Get Billingaccountsea

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
    .Synopsis
        Get all the billing scopes a the authenticated user has access to
    .Description
        This script will retrive the billing accounts and enrollment accounts the authenticated user has access to.
        
        The information is needed to determine the billingScope property value when create an subscription via the
        Microsoft.Subscription/aliases resource.  Nothing will be returned from the script if the user does not have
        access to any billing or enrollment accounts.

        The script can be used for an Enterprise Agreement account, for other agreements the script will need to be modified.


$billingAccountPath = "/providers/Microsoft.Billing/billingaccounts/?api-version=2020-05-01"

$billingAccounts = ($(Invoke-AzRestMethod -Method " GET" -path $billingAccountPath).Content | ConvertFrom-Json).value

foreach ($ba in $billingAccounts) {
    Write-WELog " Billing Account: $($ba.name)" " INFO"
   ;  $enrollmentAccountUri = " /providers/Microsoft.Billing/billingaccounts/$($ba.name)/enrollmentAccounts/?api-version=2019-10-01-preview"
   ;  $enrollmentAccounts = ($(Invoke-AzRestMethod -Method " GET" -path $enrollmentAccountUri ).Content | ConvertFrom-Json).value

    foreach($account in $enrollmentAccounts){
        Write-WELog "  Enrollment Account: $($account.name)" " INFO"
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
