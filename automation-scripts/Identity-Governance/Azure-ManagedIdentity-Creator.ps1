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

Write-Information "Creating Managed Identity: $IdentityName"

try {
    # Create user-assigned managed identity
    $Identity = New-AzUserAssignedIdentity -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $IdentityName `
        -Location $Location
    
    Write-Information "✅ Managed Identity created successfully:"
    Write-Information "  Name: $($Identity.Name)"
    Write-Information "  Client ID: $($Identity.ClientId)"
    Write-Information "  Principal ID: $($Identity.PrincipalId)"
    Write-Information "  Resource ID: $($Identity.Id)"
    Write-Information "  Location: $($Identity.Location)"
    
    # Assign role if specified
    if ($Role -and $Scope) {
        Write-Information "`nAssigning role to managed identity..."
        
        Start-Sleep -Seconds 10  # Wait for identity propagation
        
        $RoleAssignment = New-AzRoleAssignment -ErrorAction Stop `
            -ObjectId $Identity.PrincipalId `
            -RoleDefinitionName $Role `
            -Scope $Scope
        
        Write-Information "✅ Role assignment completed:"
        Write-Information "  Assignment ID: $($RoleAssignment.RoleAssignmentId)"
        Write-Information "  Role: $Role"
        Write-Information "  Scope: $Scope"
    }
    
    Write-Information "`nManaged Identity Benefits:"
    Write-Information "• No credential management required"
    Write-Information "• Automatic credential rotation"
    Write-Information "• Azure AD authentication"
    Write-Information "• No secrets in code or config"
    Write-Information "• Built-in Azure integration"
    
    Write-Information "`nUsage Examples:"
    Write-Information "Virtual Machines:"
    Write-Information "  - Assign identity to VM"
    Write-Information "  - Access Azure resources securely"
    Write-Information "  - No need to store credentials"
    
    Write-Information "`nApp Services:"
    Write-Information "  - Enable managed identity"
    Write-Information "  - Access Key Vault secrets"
    Write-Information "  - Connect to databases"
    
    Write-Information "`nPowerShell Usage:"
    Write-Information "  Connect-AzAccount -Identity -AccountId $($Identity.ClientId)"
    
    Write-Information "`nNext Steps:"
    Write-Information "1. Assign identity to Azure resources (VM, App Service, etc.)"
    Write-Information "2. Grant necessary permissions"
    Write-Information "3. Update application code to use managed identity"
    Write-Information "4. Test secure resource access"
    
} catch {
    Write-Error "Failed to create managed identity: $($_.Exception.Message)"
}
