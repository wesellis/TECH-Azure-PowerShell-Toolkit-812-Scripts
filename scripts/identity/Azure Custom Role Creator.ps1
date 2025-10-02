#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Custom Role Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RoleName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Description,
    [Parameter(Mandatory)]
    [array]$Actions,
    [Parameter()]
    [array]$NotActions = @(),
    [Parameter()]
    [array]$DataActions = @(),
    [Parameter()]
    [array]$NotDataActions = @(),
    [Parameter(ValueFromPipeline)]`n    [string]$SubscriptionId
)
Write-Output "Creating custom Azure role: $RoleName"
if (-not $SubscriptionId) {
    [string]$SubscriptionId = (Get-AzContext).Subscription.Id
}
try {
$RoleDefinition = @{
        Name = $RoleName
        Description = $Description
        Actions = $Actions
        NotActions = $NotActions
        DataActions = $DataActions
        NotDataActions = $NotDataActions
        AssignableScopes = @("/subscriptions/$SubscriptionId" )
    }
$CustomRole = New-AzRoleDefinition -Role $RoleDefinition
    Write-Output "Custom role created successfully:"
    Write-Output "Name: $($CustomRole.Name)"
    Write-Output "ID: $($CustomRole.Id)"
    Write-Output "Description: $($CustomRole.Description)"
    Write-Output "Type: $($CustomRole.RoleType)"


    Author: Wes Ellis (wes@wesellis.com)
    Write-Output " `nPermissions:"
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
    Write-Output " `nAssignable Scopes:"
    foreach ($Scope in $CustomRole.AssignableScopes) {
        Write-Output "   $Scope"
    }
    Write-Output " `nCustom Role Benefits:"
    Write-Output "Principle of least privilege"
    Write-Output "Fine-grained access control"
    Write-Output "Compliance and governance"
    Write-Output "Reduced security risk"
    Write-Output " `nNext Steps:"
    Write-Output " 1. Test the role with a pilot user"
    Write-Output " 2. Assign to users or groups as needed"
    Write-Output " 3. Monitor usage and adjust permissions"
    Write-Output " 4. Document role purpose and usage"
    Write-Output " `nCommon Action Patterns:"
    Write-Output "Read operations: */read"
    Write-Output "Write operations: */write"
    Write-Output "Delete operations: */delete"
    Write-Output "List operations: */list*"
    Write-Output "Specific resource types: Microsoft.Compute/virtualMachines/*"
} catch {
    Write-Error "Failed to create custom role: $($_.Exception.Message)"`n}
