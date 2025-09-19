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

#region Functions

Write-Information "Creating Managed Identity: $IdentityName"

try {
    # Create user-assigned managed identity
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Information = "1. Assign identity to Azure resources (VM, App Service, etc.)" Write-Information "2. Grant necessary permissions" Write-Information "3. Update application code to use managed identity" Write-Information "4. Test secure resource access"
        Location = $Location  Write-Information " Managed Identity created successfully:" Write-Information "  Name: $($Identity.Name)" Write-Information "  Client ID: $($Identity.ClientId)" Write-Information "  Principal ID: $($Identity.PrincipalId)" Write-Information "  Resource ID: $($Identity.Id)" Write-Information "  Location: $($Identity.Location)"  # Assign role if specified if ($Role
        RoleDefinitionName = $Role
        ObjectId = $Identity.PrincipalId
        ErrorAction = "Stop"
        Seconds = "10  # Wait for identity propagation  $RoleAssignment = New-AzRoleAssignment"
        Name = $IdentityName
    }
    $Identity @params
} catch {
    Write-Error "Failed to create managed identity: $($_.Exception.Message)"
}


#endregion
