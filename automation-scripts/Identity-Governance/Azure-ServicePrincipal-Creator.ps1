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

Write-Information "Creating Service Principal: $DisplayName"

try {
    # Create service principal with password
    $ServicePrincipal = New-AzADServicePrincipal -ErrorAction Stop `
        -DisplayName $DisplayName `
        -Role $Role `
        -Scope $Scope
    
    Write-Information "✅ Service Principal created successfully:"
    Write-Information "  Display Name: $($ServicePrincipal.DisplayName)"
    Write-Information "  Application ID: $($ServicePrincipal.ApplicationId)"
    Write-Information "  Object ID: $($ServicePrincipal.Id)"
    Write-Information "  Service Principal Names: $($ServicePrincipal.ServicePrincipalNames -join ', ')"
    
    # Get the secret
    $Secret = $ServicePrincipal.Secret
    if ($Secret) {
        Write-Information "`n🔑 Credentials (SAVE THESE SECURELY):"
        Write-Information "  Application (Client) ID: $($ServicePrincipal.ApplicationId)"
        Write-Information "  Client Secret: $($Secret)"
        Write-Information "  Tenant ID: $((Get-AzContext).Tenant.Id)"
    }
    
    Write-Information "`nRole Assignment:"
    Write-Information "  Role: $Role"
    if ($Scope) {
        Write-Information "  Scope: $Scope"
    } else {
        Write-Information "  Scope: Subscription level"
    }
    
    Write-Information "`n⚠️ SECURITY NOTES:"
    Write-Information "• Store credentials securely (Key Vault recommended)"
    Write-Information "• Use certificate authentication for production"
    Write-Information "• Implement credential rotation"
    Write-Information "• Follow principle of least privilege"
    
    Write-Information "`nUsage in scripts:"
    Write-Information "  Connect-AzAccount -ServicePrincipal -ApplicationId '$($ServicePrincipal.ApplicationId)' -TenantId '$((Get-AzContext).Tenant.Id)' -CertificateThumbprint '[thumbprint]'"
    
} catch {
    Write-Error "Failed to create service principal: $($_.Exception.Message)"
}
