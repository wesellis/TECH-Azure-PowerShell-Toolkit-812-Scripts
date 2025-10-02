#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Role Assignment Manager

.DESCRIPTION
    Azure automation for managing role assignments

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PrincipalId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RoleDefinitionName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Scope,

    [Parameter()]
    [string]$PrincipalType = "User"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [Role-Manager] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Managing role assignment:" "INFO"
    Write-Log "Principal ID: $PrincipalId" "INFO"
    Write-Log "Role: $RoleDefinitionName" "INFO"
    Write-Log "Scope: $Scope" "INFO"
    Write-Log "Type: $PrincipalType" "INFO"

    # Check for existing assignment
    $ExistingAssignment = Get-AzRoleAssignment -ObjectId $PrincipalId -RoleDefinitionName $RoleDefinitionName -Scope $Scope -ErrorAction SilentlyContinue

    if ($ExistingAssignment) {
        Write-Log "Role assignment already exists" "WARN"
        Write-Log "Assignment ID: $($ExistingAssignment.RoleAssignmentId)" "INFO"
        return
    }

    # Create role assignment
    $params = @{
        ErrorAction = "Stop"
        RoleDefinitionName = $RoleDefinitionName
        ObjectId = $PrincipalId
        Scope = $Scope
    }

    $Assignment = New-AzRoleAssignment @params

    Write-Log "Role assignment created successfully:" "SUCCESS"
    Write-Log "Assignment ID: $($Assignment.RoleAssignmentId)" "INFO"
    Write-Log "Principal Name: $($Assignment.DisplayName)" "INFO"
    Write-Log "Role: $($Assignment.RoleDefinitionName)" "INFO"
    Write-Log "Scope: $($Assignment.Scope)" "INFO"

    Write-Log "`nCommon Azure Roles:" "INFO"
    Write-Log "  Owner - Full access including access management" "INFO"
    Write-Log "  Contributor - Full access except access management" "INFO"
    Write-Log "  Reader - Read-only access" "INFO"
    Write-Log "  User Access Administrator - Manage user access" "INFO"
    Write-Log "  Security Administrator - Security permissions" "INFO"
    Write-Log "  Backup Contributor - Backup management" "INFO"

} catch {
    Write-Error "Failed to create role assignment: $($_.Exception.Message)"
    throw
}