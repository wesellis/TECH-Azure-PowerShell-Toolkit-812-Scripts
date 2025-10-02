#Requires -Version 7.4

<#
.SYNOPSIS
    Get Billingaccountsea - Retrieve Azure Billing Account and Enrollment Account Information

.DESCRIPTION
    Azure automation script that retrieves billing accounts and enrollment accounts that the authenticated user has access to.
    This script will retrieve the billing accounts and enrollment accounts the authenticated user has access to.
    The information is needed to determine the billingScope property value when creating a subscription via the
    Microsoft.Subscription/aliases resource. Nothing will be returned from the script if the user does not have
    access to any billing or enrollment accounts.
    The script can be used for an Enterprise Agreement account, for other agreements the script will need to be modified.

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.EXAMPLE
    PS C:\> .\Get_Billingaccountsea.ps1
    Retrieves all billing accounts and enrollment accounts the user has access to

.INPUTS
    None

.OUTPUTS
    Billing account and enrollment account information

.NOTES
    This script is designed for Enterprise Agreement accounts.
    For other agreement types, modifications may be required.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Retrieving billing accounts and enrollment accounts..."

    # Get billing accounts
    $BillingAccountPath = "/providers/Microsoft.Billing/billingaccounts/?api-version=2020-05-01"
    $BillingAccounts = ($(Invoke-AzRestMethod -Method "GET" -Path $BillingAccountPath).Content | ConvertFrom-Json).value

    foreach ($ba in $BillingAccounts) {
        Write-Output "Billing Account: $($ba.name)"

        # Get enrollment accounts for each billing account
        $EnrollmentAccountUri = "/providers/Microsoft.Billing/billingaccounts/$($ba.name)/enrollmentAccounts/?api-version=2019-10-01-preview"
        $EnrollmentAccounts = ($(Invoke-AzRestMethod -Method "GET" -Path $EnrollmentAccountUri).Content | ConvertFrom-Json).value

        foreach ($account in $EnrollmentAccounts) {
            Write-Output "  Enrollment Account: $($account.name)"
        }
    }

    if (-not $BillingAccounts -or $BillingAccounts.Count -eq 0) {
        Write-Warning "No billing accounts found. The user may not have access to any billing accounts."
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}