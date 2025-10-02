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
    [string]$RoleName,
    [Parameter(Mandatory)]
    [string]$Description,
    [Parameter(Mandatory)]
    [array]$Actions,
    [Parameter()]
    [array]$NotActions = @(),
    [Parameter()]
    [array]$DataActions = @(),
    [Parameter()]
    [array]$NotDataActions = @(),
    [Parameter()]
    [string]$SubscriptionId
)
Write-Output "Creating custom Azure role: $RoleName"
if (-not $SubscriptionId) {
    $SubscriptionId = (Get-AzContext).Subscription.Id
}
try {
    $RoleDefinition = @{
        Name = $RoleName
        Description = $Description
        Actions = $Actions
        NotActions = $NotActions
        DataActions = $DataActions
        NotDataActions = $NotDataActions
        AssignableScopes = @("/subscriptions/$SubscriptionId")
    }
    $CustomRole = New-AzRoleDefinition -Role $RoleDefinition
    Write-Output "Custom role created successfully:"
    Write-Output "Name: $($CustomRole.Name)"
    Write-Output "ID: $($CustomRole.Id)"
    Write-Output "Description: $($CustomRole.Description)"
    Write-Output "Type: $($CustomRole.RoleType)"
    Write-Output "`nPermissions:"
    Write-Output "Actions ($($Actions.Count)):"
    foreach ($Action in $Actions) {
        Write-Output "     $Action"
    }
    if ($NotActions.Count -gt 0) {
        Write-Output "NotActions ($($NotActions.Count)):"
        foreach ($NotAction in $NotActions) {
            Write-Output "     $NotAction"
        }
    }
    if ($DataActions.Count -gt 0) {
        Write-Output "DataActions ($($DataActions.Count)):"
        foreach ($DataAction in $DataActions) {
            Write-Output "     $DataAction"
        }
    }
    if ($NotDataActions.Count -gt 0) {
        Write-Output "NotDataActions ($($NotDataActions.Count)):"
        foreach ($NotDataAction in $NotDataActions) {
            Write-Output "     $NotDataAction"
        }
    }
    Write-Output "`nAssignable Scopes:"
    foreach ($Scope in $CustomRole.AssignableScopes) {
        Write-Output "   $Scope"
    }
    Write-Output "`nCustom Role Benefits:"
    Write-Output "Principle of least privilege"
    Write-Output "Fine-grained access control"
    Write-Output "Compliance and governance"
    Write-Output "Reduced security risk"
    Write-Output "`nNext Steps:"
    Write-Output "1. Test the role with a pilot user"
    Write-Output "2. Assign to users or groups as needed"
    Write-Output "3. Monitor usage and adjust permissions"
    Write-Output "4. Document role purpose and usage"
    Write-Output "`nCommon Action Patterns:"
    Write-Output "Read operations: */read"
    Write-Output "Write operations: */write"
    Write-Output "Delete operations: */delete"
    Write-Output "List operations: */list*"
    Write-Output "Specific resource types: Microsoft.Compute/virtualMachines/*"
} catch {
    Write-Error "Failed to create custom role: $($_.Exception.Message)"`n}
