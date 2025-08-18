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

Write-Information "Managing role assignment:"
Write-Information "  Principal ID: $PrincipalId"
Write-Information "  Role: $RoleDefinitionName"
Write-Information "  Scope: $Scope"
Write-Information "  Type: $PrincipalType"

try {
    # Check if assignment already exists
    $ExistingAssignment = Get-AzRoleAssignment -ObjectId $PrincipalId -RoleDefinitionName $RoleDefinitionName -Scope $Scope -ErrorAction SilentlyContinue
    
    if ($ExistingAssignment) {
        Write-Information "⚠️ Role assignment already exists"
        Write-Information "  Assignment ID: $($ExistingAssignment.RoleAssignmentId)"
        return
    }
    
    # Create new role assignment
    $Assignment = New-AzRoleAssignment -ErrorAction Stop `
        -ObjectId $PrincipalId `
        -RoleDefinitionName $RoleDefinitionName `
        -Scope $Scope
    
    Write-Information "✅ Role assignment created successfully:"
    Write-Information "  Assignment ID: $($Assignment.RoleAssignmentId)"
    Write-Information "  Principal Name: $($Assignment.DisplayName)"
    Write-Information "  Role: $($Assignment.RoleDefinitionName)"
    Write-Information "  Scope: $($Assignment.Scope)"
    
} catch {
    Write-Error "Failed to create role assignment: $($_.Exception.Message)"
}

Write-Information "`nCommon Azure Roles:"
Write-Information "• Owner - Full access including access management"
Write-Information "• Contributor - Full access except access management"
Write-Information "• Reader - Read-only access"
Write-Information "• User Access Administrator - Manage user access"
Write-Information "• Security Administrator - Security permissions"
Write-Information "• Backup Contributor - Backup management"
