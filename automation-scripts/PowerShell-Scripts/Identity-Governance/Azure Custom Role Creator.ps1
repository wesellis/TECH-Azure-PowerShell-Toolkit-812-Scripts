<#
.SYNOPSIS
    We Enhanced Azure Custom Role Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERoleName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDescription,
    
    [Parameter(Mandatory=$true)]
    [array]$WEActions,
    
    [Parameter(Mandatory=$false)]
    [array]$WENotActions = @(),
    
    [Parameter(Mandatory=$false)]
    [array]$WEDataActions = @(),
    
    [Parameter(Mandatory=$false)]
    [array]$WENotDataActions = @(),
    
    [Parameter(Mandatory=$false)]
    [string]$WESubscriptionId
)

Write-WELog " Creating custom Azure role: $WERoleName" " INFO"

if (-not $WESubscriptionId) {
    $WESubscriptionId = (Get-AzContext).Subscription.Id
}

try {
    # Create role definition object
    $WERoleDefinition = @{
        Name = $WERoleName
        Description = $WEDescription
        Actions = $WEActions
        NotActions = $WENotActions
        DataActions = $WEDataActions
        NotDataActions = $WENotDataActions
        AssignableScopes = @(" /subscriptions/$WESubscriptionId")
    }
    
    # Create the custom role
   ;  $WECustomRole = New-AzRoleDefinition -Role $WERoleDefinition
    
    Write-WELog " ✅ Custom role created successfully:" " INFO"
    Write-WELog "  Name: $($WECustomRole.Name)" " INFO"
    Write-WELog "  ID: $($WECustomRole.Id)" " INFO"
    Write-WELog "  Description: $($WECustomRole.Description)" " INFO"
    Write-WELog "  Type: $($WECustomRole.RoleType)" " INFO"
    
    Write-WELog " `nPermissions:" " INFO"
    Write-WELog "  Actions ($($WEActions.Count)):" " INFO"
    foreach ($WEAction in $WEActions) {
        Write-WELog "    • $WEAction" " INFO"
    }
    
    if ($WENotActions.Count -gt 0) {
        Write-WELog "  NotActions ($($WENotActions.Count)):" " INFO"
        foreach ($WENotAction in $WENotActions) {
            Write-WELog "    • $WENotAction" " INFO"
        }
    }
    
    if ($WEDataActions.Count -gt 0) {
        Write-WELog "  DataActions ($($WEDataActions.Count)):" " INFO"
        foreach ($WEDataAction in $WEDataActions) {
            Write-WELog "    • $WEDataAction" " INFO"
        }
    }
    
    if ($WENotDataActions.Count -gt 0) {
        Write-WELog "  NotDataActions ($($WENotDataActions.Count)):" " INFO"
        foreach ($WENotDataAction in $WENotDataActions) {
            Write-WELog "    • $WENotDataAction" " INFO"
        }
    }
    
    Write-WELog " `nAssignable Scopes:" " INFO"
    foreach ($WEScope in $WECustomRole.AssignableScopes) {
        Write-WELog "  • $WEScope" " INFO"
    }
    
    Write-WELog " `nCustom Role Benefits:" " INFO"
    Write-WELog " • Principle of least privilege" " INFO"
    Write-WELog " • Fine-grained access control" " INFO"
    Write-WELog " • Compliance and governance" " INFO"
    Write-WELog " • Reduced security risk" " INFO"
    
    Write-WELog " `nNext Steps:" " INFO"
    Write-WELog " 1. Test the role with a pilot user" " INFO"
    Write-WELog " 2. Assign to users or groups as needed" " INFO"
    Write-WELog " 3. Monitor usage and adjust permissions" " INFO"
    Write-WELog " 4. Document role purpose and usage" " INFO"
    
    Write-WELog " `nCommon Action Patterns:" " INFO"
    Write-WELog " • Read operations: */read" " INFO"
    Write-WELog " • Write operations: */write" " INFO"
    Write-WELog " • Delete operations: */delete" " INFO"
    Write-WELog " • List operations: */list*" " INFO"
    Write-WELog " • Specific resource types: Microsoft.Compute/virtualMachines/*" " INFO"
    
} catch {
    Write-Error " Failed to create custom role: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================