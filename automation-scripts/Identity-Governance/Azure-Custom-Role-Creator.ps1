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
    [string]$RoleName,
    
    [Parameter(Mandatory=$true)]
    [string]$Description,
    
    [Parameter(Mandatory=$true)]
    [array]$Actions,
    
    [Parameter(Mandatory=$false)]
    [array]$NotActions = @(),
    
    [Parameter(Mandatory=$false)]
    [array]$DataActions = @(),
    
    [Parameter(Mandatory=$false)]
    [array]$NotDataActions = @(),
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

#region Functions

Write-Information "Creating custom Azure role: $RoleName"

if (-not $SubscriptionId) {
    $SubscriptionId = (Get-AzContext).Subscription.Id
}

try {
    # Create role definition object
    $RoleDefinition = @{
        Name = $RoleName
        Description = $Description
        Actions = $Actions
        NotActions = $NotActions
        DataActions = $DataActions
        NotDataActions = $NotDataActions
        AssignableScopes = @("/subscriptions/$SubscriptionId")
    }
    
    # Create the custom role
    $CustomRole = New-AzRoleDefinition -Role $RoleDefinition
    
    Write-Information " Custom role created successfully:"
    Write-Information "  Name: $($CustomRole.Name)"
    Write-Information "  ID: $($CustomRole.Id)"
    Write-Information "  Description: $($CustomRole.Description)"
    Write-Information "  Type: $($CustomRole.RoleType)"
    
    Write-Information "`nPermissions:"
    Write-Information "  Actions ($($Actions.Count)):"
    foreach ($Action in $Actions) {
        Write-Information "    • $Action"
    }
    
    if ($NotActions.Count -gt 0) {
        Write-Information "  NotActions ($($NotActions.Count)):"
        foreach ($NotAction in $NotActions) {
            Write-Information "    • $NotAction"
        }
    }
    
    if ($DataActions.Count -gt 0) {
        Write-Information "  DataActions ($($DataActions.Count)):"
        foreach ($DataAction in $DataActions) {
            Write-Information "    • $DataAction"
        }
    }
    
    if ($NotDataActions.Count -gt 0) {
        Write-Information "  NotDataActions ($($NotDataActions.Count)):"
        foreach ($NotDataAction in $NotDataActions) {
            Write-Information "    • $NotDataAction"
        }
    }
    
    Write-Information "`nAssignable Scopes:"
    foreach ($Scope in $CustomRole.AssignableScopes) {
        Write-Information "  • $Scope"
    }
    
    Write-Information "`nCustom Role Benefits:"
    Write-Information "• Principle of least privilege"
    Write-Information "• Fine-grained access control"
    Write-Information "• Compliance and governance"
    Write-Information "• Reduced security risk"
    
    Write-Information "`nNext Steps:"
    Write-Information "1. Test the role with a pilot user"
    Write-Information "2. Assign to users or groups as needed"
    Write-Information "3. Monitor usage and adjust permissions"
    Write-Information "4. Document role purpose and usage"
    
    Write-Information "`nCommon Action Patterns:"
    Write-Information "• Read operations: */read"
    Write-Information "• Write operations: */write"
    Write-Information "• Delete operations: */delete"
    Write-Information "• List operations: */list*"
    Write-Information "• Specific resource types: Microsoft.Compute/virtualMachines/*"
    
} catch {
    Write-Error "Failed to create custom role: $($_.Exception.Message)"
}


#endregion
