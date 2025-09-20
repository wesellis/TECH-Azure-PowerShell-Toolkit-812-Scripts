#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Role Assignment Manager

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
[OutputType([PSObject])]
 {
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
       Scope = $Scope  Write-Host "Role assignment created successfully:" "INFO"Write-Host "Assignment ID: $($Assignment.RoleAssignmentId)" "INFO"Write-Host "Principal Name: $($Assignment.DisplayName)" "INFO"Write-Host "Role: $($Assignment.RoleDefinitionName)"Write-Host "Scope: $($Assignment.Scope)" " INFO
   }
   ; @params
} catch {
    Write-Error "Failed to create role assignment: $($_.Exception.Message)"
}
Write-Host " `nCommon Azure Roles:"
Write-Host "Owner - Full access including access management"
Write-Host "Contributor - Full access except access management"
Write-Host "Reader - Read-only access"
Write-Host "User Access Administrator - Manage user access"
Write-Host "Security Administrator - Security permissions"
Write-Host "Backup Contributor - Backup management"


