#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$DisplayName,
    [Parameter()]
    [string]$Role = "Contributor",
    [Parameter()]
    [string]$Scope,
    [Parameter()]
    [int]$PasswordValidityMonths = 12
)
Write-Output "Creating Service Principal: $DisplayName"
try {
    $params = @{
        DisplayName = $DisplayName
        Information = "  Connect-AzAccount"
        TenantId = $((Get-AzContext).Tenant.Id)
        ApplicationId = $($ServicePrincipal.ApplicationId)
        CertificateThumbprint = "[thumbprint]"
        Scope = $Scope  Write-Output "Service Principal created successfully:" Write-Output "Display Name: $($ServicePrincipal.DisplayName)"Write-Output "Application ID: $($ServicePrincipal.ApplicationId)"Write-Output "Object ID: $($ServicePrincipal.Id)"Write-Host "Service Principal Names: $($ServicePrincipal.ServicePrincipalNames
        ErrorAction = "Stop"
        Role = $Role
    }
} catch {
    Write-Error "Failed to create service principal: $($_.Exception.Message)"`n}
