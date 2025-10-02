#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$PrincipalId,
    [Parameter(Mandatory)]
    [string]$RoleDefinitionName,
    [Parameter(Mandatory)]
    [string]$Scope,
    [Parameter()]
    [string]$PrincipalType = "User"
)
Write-Output "Managing role assignment:"
Write-Output "Principal ID: $PrincipalId"
Write-Output "Role: $RoleDefinitionName"
Write-Output "Scope: $Scope"
Write-Output "Type: $PrincipalType"
try {
    $ExistingAssignment = Get-AzRoleAssignment -ObjectId $PrincipalId -RoleDefinitionName $RoleDefinitionName -Scope $Scope -ErrorAction SilentlyContinue
    if ($ExistingAssignment) {
        Write-Output "[WARN] Role assignment already exists"
        Write-Output "Assignment ID: $($ExistingAssignment.RoleAssignmentId)"
        return
    }
    $params = @{
        ErrorAction = "Stop"
        RoleDefinitionName = $RoleDefinitionName
        ObjectId = $PrincipalId
        Scope = $Scope  Write-Output "Role assignment created successfully:" Write-Output "Assignment ID: $($Assignment.RoleAssignmentId)"Write-Output "Principal Name: $($Assignment.DisplayName)"Write-Output "Role: $($Assignment.RoleDefinitionName)"Write-Host "Scope: $($Assignment.Scope)
    }
} catch {
    Write-Error "Failed to create role assignment: $($_.Exception.Message)"
}
Write-Output "`nCommon Azure Roles:"
Write-Output "Owner - Full access including access management"
Write-Output "Contributor - Full access except access management"
Write-Output "Reader - Read-only access"
Write-Output "User Access Administrator - Manage user access"
Write-Output "Security Administrator - Security permissions"
Write-Output "Backup Contributor - Backup management"



