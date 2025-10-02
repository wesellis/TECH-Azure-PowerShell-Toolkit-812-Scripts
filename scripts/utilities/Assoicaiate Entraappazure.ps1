#Requires -Version 7.4
#Requires -Modules Az.Accounts, Az.Resources

<#
.SYNOPSIS
    Associate Entra App with Azure Subscription

.DESCRIPTION
    Associates an Entra (Azure AD) application with an Azure subscription
    for authentication and authorization purposes

.PARAMETER SubscriptionId
    The Azure subscription ID to associate with

.PARAMETER ApplicationId
    The Entra application (client) ID

.PARAMETER TenantId
    The Azure Active Directory tenant ID

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
    [string]$ApplicationId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
    [string]$TenantId,

    [Parameter()]
    [string]$RoleDefinitionName = "Contributor"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    Write-Verbose "Connecting to Azure..."
    $context = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $context) {
        Write-Output "Not currently connected to Azure. Please authenticate..."
        Connect-AzAccount -TenantId $TenantId -ErrorAction Stop
    }

    Write-Output "Setting subscription context to: $SubscriptionId"
    Set-AzContext -SubscriptionId $SubscriptionId -TenantId $TenantId -ErrorAction Stop

    Write-Verbose "Getting service principal for application ID: $ApplicationId"
    $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $ApplicationId -ErrorAction SilentlyContinue

    if (-not $servicePrincipal) {
        Write-Output "Service principal not found for application ID: $ApplicationId"
        Write-Output "Creating service principal..."
        $servicePrincipal = New-AzADServicePrincipal -ApplicationId $ApplicationId -ErrorAction Stop
        Write-Output "Service principal created successfully"
    }
    else {
        Write-Output "Service principal already exists for application ID: $ApplicationId"
    }

    Write-Verbose "Checking existing role assignments..."
    $existingAssignment = Get-AzRoleAssignment -ObjectId $servicePrincipal.Id `
        -RoleDefinitionName $RoleDefinitionName `
        -Scope "/subscriptions/$SubscriptionId" `
        -ErrorAction SilentlyContinue

    if (-not $existingAssignment) {
        Write-Output "Assigning '$RoleDefinitionName' role to service principal..."
        New-AzRoleAssignment -ObjectId $servicePrincipal.Id `
            -RoleDefinitionName $RoleDefinitionName `
            -Scope "/subscriptions/$SubscriptionId" `
            -ErrorAction Stop

        Write-Output "Role assignment completed successfully"
    }
    else {
        Write-Output "Service principal already has '$RoleDefinitionName' role assigned"
    }

    Write-Output "`nAssociation Summary:"
    Write-Output "===================="
    Write-Output "Subscription ID: $SubscriptionId"
    Write-Output "Tenant ID: $TenantId"
    Write-Output "Application ID: $ApplicationId"
    Write-Output "Service Principal ID: $($servicePrincipal.Id)"
    Write-Output "Role: $RoleDefinitionName"
    Write-Output "`nEntra app successfully associated with Azure subscription"
}
catch {
    Write-Error "Failed to associate Entra app with Azure subscription: $_"
    throw
}