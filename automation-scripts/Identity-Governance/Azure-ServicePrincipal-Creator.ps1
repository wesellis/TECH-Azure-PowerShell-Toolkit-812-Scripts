# ============================================================================
# Script Name: Azure Service Principal Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Active Directory service principals for automation
# ============================================================================

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

Write-Host "Creating Service Principal: $DisplayName"

try {
    # Create service principal with password
    $ServicePrincipal = New-AzADServicePrincipal `
        -DisplayName $DisplayName `
        -Role $Role `
        -Scope $Scope
    
    Write-Host "✅ Service Principal created successfully:"
    Write-Host "  Display Name: $($ServicePrincipal.DisplayName)"
    Write-Host "  Application ID: $($ServicePrincipal.ApplicationId)"
    Write-Host "  Object ID: $($ServicePrincipal.Id)"
    Write-Host "  Service Principal Names: $($ServicePrincipal.ServicePrincipalNames -join ', ')"
    
    # Get the secret
    $Secret = $ServicePrincipal.Secret
    if ($Secret) {
        Write-Host "`n🔑 Credentials (SAVE THESE SECURELY):"
        Write-Host "  Application (Client) ID: $($ServicePrincipal.ApplicationId)"
        Write-Host "  Client Secret: $($Secret)"
        Write-Host "  Tenant ID: $((Get-AzContext).Tenant.Id)"
    }
    
    Write-Host "`nRole Assignment:"
    Write-Host "  Role: $Role"
    if ($Scope) {
        Write-Host "  Scope: $Scope"
    } else {
        Write-Host "  Scope: Subscription level"
    }
    
    Write-Host "`n⚠️ SECURITY NOTES:"
    Write-Host "• Store credentials securely (Key Vault recommended)"
    Write-Host "• Use certificate authentication for production"
    Write-Host "• Implement credential rotation"
    Write-Host "• Follow principle of least privilege"
    
    Write-Host "`nUsage in scripts:"
    Write-Host "  Connect-AzAccount -ServicePrincipal -ApplicationId '$($ServicePrincipal.ApplicationId)' -TenantId '$((Get-AzContext).Tenant.Id)' -CertificateThumbprint '[thumbprint]'"
    
} catch {
    Write-Error "Failed to create service principal: $($_.Exception.Message)"
}
