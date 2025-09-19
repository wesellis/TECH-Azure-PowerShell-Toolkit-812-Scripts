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
    [string]$PrincipalId,
    
    [Parameter(Mandatory=$true)]
    [string]$RoleDefinitionName,
    
    [Parameter(Mandatory=$true)]
    [string]$Scope,
    
    [Parameter(Mandatory=$false)]
    [string]$PrincipalType = "User"
)

#region Functions

Write-Information "Managing role assignment:"
Write-Information "  Principal ID: $PrincipalId"
Write-Information "  Role: $RoleDefinitionName"
Write-Information "  Scope: $Scope"
Write-Information "  Type: $PrincipalType"

try {
    # Check if assignment already exists
    $ExistingAssignment = Get-AzRoleAssignment -ObjectId $PrincipalId -RoleDefinitionName $RoleDefinitionName -Scope $Scope -ErrorAction SilentlyContinue
    
    if ($ExistingAssignment) {
        Write-Information "[WARN] Role assignment already exists"
        Write-Information "  Assignment ID: $($ExistingAssignment.RoleAssignmentId)"
        return
    }
    
    # Create new role assignment
    $params = @{
        ErrorAction = "Stop"
        RoleDefinitionName = $RoleDefinitionName
        ObjectId = $PrincipalId
        Scope = $Scope  Write-Information " Role assignment created successfully:" Write-Information "  Assignment ID: $($Assignment.RoleAssignmentId)" Write-Information "  Principal Name: $($Assignment.DisplayName)" Write-Information "  Role: $($Assignment.RoleDefinitionName)" Write-Information "  Scope: $($Assignment.Scope)
    }
    $Assignment @params
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


#endregion
