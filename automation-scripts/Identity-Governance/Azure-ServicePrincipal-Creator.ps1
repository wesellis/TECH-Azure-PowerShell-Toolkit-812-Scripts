#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$DisplayName,
    
    [Parameter(Mandatory=$false)]
    [string]$Role = "Contributor",
    
    [Parameter(Mandatory=$false)]
    [string]$Scope,
    
    [Parameter(Mandatory=$false)]
    [int]$PasswordValidityMonths = 12
)

#region Functions

Write-Information "Creating Service Principal: $DisplayName"

try {
    # Create service principal with password
    $params = @{
        DisplayName = $DisplayName
        Information = "  Connect-AzAccount"
        TenantId = $((Get-AzContext).Tenant.Id)
        ApplicationId = $($ServicePrincipal.ApplicationId)
        CertificateThumbprint = "[thumbprint]"
        Scope = $Scope  Write-Information " Service Principal created successfully:" Write-Information "  Display Name: $($ServicePrincipal.DisplayName)" Write-Information "  Application ID: $($ServicePrincipal.ApplicationId)" Write-Information "  Object ID: $($ServicePrincipal.Id)" Write-Information "  Service Principal Names: $($ServicePrincipal.ServicePrincipalNames
        ErrorAction = "Stop"
        Role = $Role
    }
    $ServicePrincipal @params
} catch {
    Write-Error "Failed to create service principal: $($_.Exception.Message)"
}


#endregion
