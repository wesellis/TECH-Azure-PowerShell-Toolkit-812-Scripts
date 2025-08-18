<#
.SYNOPSIS
    Azure Role Assignment Manager

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

<#
.SYNOPSIS
    We Enhanced Azure Role Assignment Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPrincipalId,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERoleDefinitionName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEScope,
    
    [Parameter(Mandatory=$false)]
    [string]$WEPrincipalType = " User"
)

Write-WELog " Managing role assignment:" " INFO"
Write-WELog "  Principal ID: $WEPrincipalId" " INFO"
Write-WELog "  Role: $WERoleDefinitionName" " INFO"
Write-WELog "  Scope: $WEScope" " INFO"
Write-WELog "  Type: $WEPrincipalType" " INFO"

try {
    # Check if assignment already exists
   ;  $WEExistingAssignment = Get-AzRoleAssignment -ObjectId $WEPrincipalId -RoleDefinitionName $WERoleDefinitionName -Scope $WEScope -ErrorAction SilentlyContinue
    
    if ($WEExistingAssignment) {
        Write-WELog " ⚠️ Role assignment already exists" " INFO"
        Write-WELog "  Assignment ID: $($WEExistingAssignment.RoleAssignmentId)" " INFO"
        return
    }
    
    # Create new role assignment
   ;  $WEAssignment = New-AzRoleAssignment -ErrorAction Stop `
        -ObjectId $WEPrincipalId `
        -RoleDefinitionName $WERoleDefinitionName `
        -Scope $WEScope
    
    Write-WELog " ✅ Role assignment created successfully:" " INFO"
    Write-WELog "  Assignment ID: $($WEAssignment.RoleAssignmentId)" " INFO"
    Write-WELog "  Principal Name: $($WEAssignment.DisplayName)" " INFO"
    Write-WELog "  Role: $($WEAssignment.RoleDefinitionName)" " INFO"
    Write-WELog "  Scope: $($WEAssignment.Scope)" " INFO"
    
} catch {
    Write-Error " Failed to create role assignment: $($_.Exception.Message)"
}

Write-WELog " `nCommon Azure Roles:" " INFO"
Write-WELog " • Owner - Full access including access management" " INFO"
Write-WELog " • Contributor - Full access except access management" " INFO"
Write-WELog " • Reader - Read-only access" " INFO"
Write-WELog " • User Access Administrator - Manage user access" " INFO"
Write-WELog " • Security Administrator - Security permissions" " INFO"
Write-WELog " • Backup Contributor - Backup management" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================