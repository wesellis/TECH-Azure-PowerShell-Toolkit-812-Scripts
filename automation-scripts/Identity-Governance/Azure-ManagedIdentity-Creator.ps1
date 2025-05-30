# ============================================================================
# Script Name: Azure Managed Identity Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates and manages Azure Managed Identities for secure resource access
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$IdentityName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$Role = "Reader",
    
    [Parameter(Mandatory=$false)]
    [string]$Scope
)

Write-Host "Creating Managed Identity: $IdentityName"

try {
    # Create user-assigned managed identity
    $Identity = New-AzUserAssignedIdentity `
        -ResourceGroupName $ResourceGroupName `
        -Name $IdentityName `
        -Location $Location
    
    Write-Host "✅ Managed Identity created successfully:"
    Write-Host "  Name: $($Identity.Name)"
    Write-Host "  Client ID: $($Identity.ClientId)"
    Write-Host "  Principal ID: $($Identity.PrincipalId)"
    Write-Host "  Resource ID: $($Identity.Id)"
    Write-Host "  Location: $($Identity.Location)"
    
    # Assign role if specified
    if ($Role -and $Scope) {
        Write-Host "`nAssigning role to managed identity..."
        
        Start-Sleep -Seconds 10  # Wait for identity propagation
        
        $RoleAssignment = New-AzRoleAssignment `
            -ObjectId $Identity.PrincipalId `
            -RoleDefinitionName $Role `
            -Scope $Scope
        
        Write-Host "✅ Role assignment completed:"
        Write-Host "  Role: $Role"
        Write-Host "  Scope: $Scope"
    }
    
    Write-Host "`nManaged Identity Benefits:"
    Write-Host "• No credential management required"
    Write-Host "• Automatic credential rotation"
    Write-Host "• Azure AD authentication"
    Write-Host "• No secrets in code or config"
    Write-Host "• Built-in Azure integration"
    
    Write-Host "`nUsage Examples:"
    Write-Host "Virtual Machines:"
    Write-Host "  - Assign identity to VM"
    Write-Host "  - Access Azure resources securely"
    Write-Host "  - No need to store credentials"
    
    Write-Host "`nApp Services:"
    Write-Host "  - Enable managed identity"
    Write-Host "  - Access Key Vault secrets"
    Write-Host "  - Connect to databases"
    
    Write-Host "`nPowerShell Usage:"
    Write-Host "  Connect-AzAccount -Identity -AccountId $($Identity.ClientId)"
    
    Write-Host "`nNext Steps:"
    Write-Host "1. Assign identity to Azure resources (VM, App Service, etc.)"
    Write-Host "2. Grant necessary permissions"
    Write-Host "3. Update application code to use managed identity"
    Write-Host "4. Test secure resource access"
    
} catch {
    Write-Error "Failed to create managed identity: $($_.Exception.Message)"
}
