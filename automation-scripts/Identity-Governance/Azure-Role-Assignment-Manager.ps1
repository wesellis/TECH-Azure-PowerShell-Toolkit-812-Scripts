# ============================================================================
# Script Name: Azure Role Assignment Manager
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Manages Azure role assignments for users, groups, and service principals
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$PrincipalId,
    
    [Parameter(Mandatory=$true)]
    [string]$RoleDefinitionName,
    
    [Parameter(Mandatory=$true)]
    [string]$Scope,
    
    [Parameter(Mandatory=$false)]
    [string]$PrincipalType = "User"
)

Write-Host "Managing role assignment:"
Write-Host "  Principal ID: $PrincipalId"
Write-Host "  Role: $RoleDefinitionName"
Write-Host "  Scope: $Scope"
Write-Host "  Type: $PrincipalType"

try {
    # Check if assignment already exists
    $ExistingAssignment = Get-AzRoleAssignment -ObjectId $PrincipalId -RoleDefinitionName $RoleDefinitionName -Scope $Scope -ErrorAction SilentlyContinue
    
    if ($ExistingAssignment) {
        Write-Host "⚠️ Role assignment already exists"
        Write-Host "  Assignment ID: $($ExistingAssignment.RoleAssignmentId)"
        return
    }
    
    # Create new role assignment
    $Assignment = New-AzRoleAssignment `
        -ObjectId $PrincipalId `
        -RoleDefinitionName $RoleDefinitionName `
        -Scope $Scope
    
    Write-Host "✅ Role assignment created successfully:"
    Write-Host "  Assignment ID: $($Assignment.RoleAssignmentId)"
    Write-Host "  Principal Name: $($Assignment.DisplayName)"
    Write-Host "  Role: $($Assignment.RoleDefinitionName)"
    Write-Host "  Scope: $($Assignment.Scope)"
    
} catch {
    Write-Error "Failed to create role assignment: $($_.Exception.Message)"
}

Write-Host "`nCommon Azure Roles:"
Write-Host "• Owner - Full access including access management"
Write-Host "• Contributor - Full access except access management"
Write-Host "• Reader - Read-only access"
Write-Host "• User Access Administrator - Manage user access"
Write-Host "• Security Administrator - Security permissions"
Write-Host "• Backup Contributor - Backup management"
