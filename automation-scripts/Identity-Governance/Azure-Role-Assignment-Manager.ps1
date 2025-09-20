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
    [string]$PrincipalId,
    [Parameter(Mandatory)]
    [string]$RoleDefinitionName,
    [Parameter(Mandatory)]
    [string]$Scope,
    [Parameter()]
    [string]$PrincipalType = "User"
)
Write-Host "Managing role assignment:"
Write-Host "Principal ID: $PrincipalId"
Write-Host "Role: $RoleDefinitionName"
Write-Host "Scope: $Scope"
Write-Host "Type: $PrincipalType"
try {
    # Check if assignment already exists
    $ExistingAssignment = Get-AzRoleAssignment -ObjectId $PrincipalId -RoleDefinitionName $RoleDefinitionName -Scope $Scope -ErrorAction SilentlyContinue
    if ($ExistingAssignment) {
        Write-Host "[WARN] Role assignment already exists"
        Write-Host "Assignment ID: $($ExistingAssignment.RoleAssignmentId)"
        return
    }
    # Create new role assignment
    $params = @{
        ErrorAction = "Stop"
        RoleDefinitionName = $RoleDefinitionName
        ObjectId = $PrincipalId
        Scope = $Scope  Write-Host "Role assignment created successfully:" Write-Host "Assignment ID: $($Assignment.RoleAssignmentId)"Write-Host "Principal Name: $($Assignment.DisplayName)"Write-Host "Role: $($Assignment.RoleDefinitionName)"Write-Host "Scope: $($Assignment.Scope)
    }
    # Command with splatting - needs proper cmdlet
} catch {
    Write-Error "Failed to create role assignment: $($_.Exception.Message)"
}
Write-Host "`nCommon Azure Roles:"
Write-Host "Owner - Full access including access management"
Write-Host "Contributor - Full access except access management"
Write-Host "Reader - Read-only access"
Write-Host "User Access Administrator - Manage user access"
Write-Host "Security Administrator - Security permissions"
Write-Host "Backup Contributor - Backup management"

