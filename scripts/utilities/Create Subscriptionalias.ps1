#Requires -Version 7.4

<#
.SYNOPSIS
    Create Subscription Alias

.DESCRIPTION
    Azure automation script to create a subscription via an alias.
    This script creates a subscription via the Microsoft.Subscription/aliases resource.
    The user running the script must be authenticated and have permission to create the subscription at the specified billing scope.
    The script is designed for Enterprise Agreement accounts.

.PARAMETER AliasName
    The alias name for the subscription

.PARAMETER DisplayName
    The display name for the subscription (defaults to AliasName)

.PARAMETER WorkLoad
    The workload type for the subscription (DevTest or Production)

.PARAMETER BillingAccount
    The billing account identifier

.PARAMETER EnrollmentAccount
    The enrollment account identifier

.NOTES
    Version: 1.0
    Author: Wes Ellis (wes@wesellis.com)
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'The alias name for the subscription')]
    [string]$AliasName,

    [Parameter(Mandatory = $false, HelpMessage = 'The display name for the subscription')]
    [string]$DisplayName = $AliasName,

    [Parameter(Mandatory = $false, HelpMessage = 'The workload type for the subscription')]
    [ValidateSet("DevTest", "Production")]
    [string]$WorkLoad = "DevTest",

    [Parameter(Mandatory = $true, HelpMessage = 'The billing account identifier')]
    [string]$BillingAccount,

    [Parameter(Mandatory = $true, HelpMessage = 'The enrollment account identifier')]
    [string]$EnrollmentAccount
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Creating subscription alias: $AliasName"

    $body = @{
        properties = @{
            workload     = $WorkLoad
            displayName  = $DisplayName
            billingScope = "/providers/Microsoft.Billing/billingAccounts/$BillingAccount/enrollmentAccounts/$EnrollmentAccount"
        }
    }

    $uri = "/providers/Microsoft.Subscription/aliases/$($AliasName)?api-version=2020-09-01"
    $BodyJSON = $body | ConvertTo-Json -Compress -Depth 30

    Write-Output "Initiating subscription creation..."
    Invoke-AzRestMethod -Method "PUT" -Path $uri -Payload $BodyJSON

    do {
        Start-Sleep 5
        $status = (Invoke-AzRestMethod -Method "GET" -path $uri -Verbose).Content | ConvertFrom-Json
        Write-Output "Provisioning State: $($status.properties.provisioningState)"
    } while ($status.properties.provisioningState -eq "Running" -or $status.properties.provisioningState -eq "Accepted")

    Write-Output "Subscription creation completed."
    $status | ConvertTo-Json -Depth 30
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}