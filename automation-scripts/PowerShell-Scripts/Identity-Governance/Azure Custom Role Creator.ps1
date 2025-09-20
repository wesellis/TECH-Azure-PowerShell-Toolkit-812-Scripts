<#
.SYNOPSIS
    Azure Custom Role Creator

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
    [Parameter()]
    [string]$SubscriptionId
)
Write-Host "Creating custom Azure role: $RoleName"
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
        AssignableScopes = @(" /subscriptions/$SubscriptionId" )
    }
    # Create the custom role
$CustomRole = New-AzRoleDefinition -Role $RoleDefinition
    Write-Host "Custom role created successfully:"
    Write-Host "Name: $($CustomRole.Name)"
    Write-Host "ID: $($CustomRole.Id)"
    Write-Host "Description: $($CustomRole.Description)"
    Write-Host "Type: $($CustomRole.RoleType)"
#>
    Write-Host " `nPermissions:"
    Write-Host "Actions ($($Actions.Count)):"
    foreach ($Action in $Actions) {
        Write-Host "     $Action"
    }
    if ($NotActions.Count -gt 0) {
        Write-Host "NotActions ($($NotActions.Count)):"
        foreach ($NotAction in $NotActions) {
            Write-Host "     $NotAction"
        }
    }
    if ($DataActions.Count -gt 0) {
        Write-Host "DataActions ($($DataActions.Count)):"
        foreach ($DataAction in $DataActions) {
            Write-Host "     $DataAction"
        }
    }
    if ($NotDataActions.Count -gt 0) {
        Write-Host "NotDataActions ($($NotDataActions.Count)):"
        foreach ($NotDataAction in $NotDataActions) {
            Write-Host "     $NotDataAction"
        }
    }
    Write-Host " `nAssignable Scopes:"
    foreach ($Scope in $CustomRole.AssignableScopes) {
        Write-Host "   $Scope"
    }
    Write-Host " `nCustom Role Benefits:"
    Write-Host "Principle of least privilege"
    Write-Host "Fine-grained access control"
    Write-Host "Compliance and governance"
    Write-Host "Reduced security risk"
    Write-Host " `nNext Steps:"
    Write-Host " 1. Test the role with a pilot user"
    Write-Host " 2. Assign to users or groups as needed"
    Write-Host " 3. Monitor usage and adjust permissions"
    Write-Host " 4. Document role purpose and usage"
    Write-Host " `nCommon Action Patterns:"
    Write-Host "Read operations: */read"
    Write-Host "Write operations: */write"
    Write-Host "Delete operations: */delete"
    Write-Host "List operations: */list*"
    Write-Host "Specific resource types: Microsoft.Compute/virtualMachines/*"
} catch {
    Write-Error "Failed to create custom role: $($_.Exception.Message)"
}

