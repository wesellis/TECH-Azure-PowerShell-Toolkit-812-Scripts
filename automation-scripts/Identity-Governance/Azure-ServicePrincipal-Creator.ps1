#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$DisplayName,
    [Parameter()]
    [string]$Role = "Contributor",
    [Parameter()]
    [string]$Scope,
    [Parameter()]
    [int]$PasswordValidityMonths = 12
)
Write-Host "Creating Service Principal: $DisplayName"
try {
    # Create service principal with password
    $params = @{
        DisplayName = $DisplayName
        Information = "  Connect-AzAccount"
        TenantId = $((Get-AzContext).Tenant.Id)
        ApplicationId = $($ServicePrincipal.ApplicationId)
        CertificateThumbprint = "[thumbprint]"
        Scope = $Scope  Write-Host "Service Principal created successfully:" Write-Host "Display Name: $($ServicePrincipal.DisplayName)"Write-Host "Application ID: $($ServicePrincipal.ApplicationId)"Write-Host "Object ID: $($ServicePrincipal.Id)"Write-Host "Service Principal Names: $($ServicePrincipal.ServicePrincipalNames
        ErrorAction = "Stop"
        Role = $Role
    }
    # Command with splatting - needs proper cmdlet
} catch {
    Write-Error "Failed to create service principal: $($_.Exception.Message)"
}

