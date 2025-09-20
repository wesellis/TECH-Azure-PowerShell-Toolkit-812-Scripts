#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Manages RBAC role assignments within subscriptions, management groups, or resource groups

.DESCRIPTION
    RBAC assignments at various scopes. Supports bulk operations, role definition management,
    and compliance reporting with full audit trail capabilities.
.PARAMETER Action
    The action to perform: Add, Remove, Audit, Validate, Export, Import
.PARAMETER PrincipalId
    Object ID of the user, group, service principal, or managed identity
.PARAMETER PrincipalType
    Type of principal: User, Group, ServicePrincipal, ManagedIdentity
.PARAMETER RoleDefinitionName
    Name of the built-in or custom role (e.g., 'Contributor', 'Reader', 'Owner')
.PARAMETER RoleDefinitionId
    GUID of the role definition (alternative to RoleDefinitionName)
.PARAMETER Scope
    Scope at which to apply the role assignment (subscription/resource group/resource)
.PARAMETER ManagementGroupId
    Management group ID for cross-subscription operations
.PARAMETER ResourceGroupName
    Target resource group name for scoped assignments
.PARAMETER RemoveOrphaned
    Remove role assignments for deleted principals
.PARAMETER ExportPath
    Path to export audit results or role assignments
.PARAMETER ImportPath
    Path to import bulk role assignments from CSV/JSON
.PARAMETER WhatIf
    Preview changes without applying them
.PARAMETER Confirm
    Prompt for confirmation before making changes
.EXAMPLE
    .\manage-role-assignments.ps1 -Action Add -PrincipalId "xxxx-xxxx" -RoleDefinitionName "Contributor" -ResourceGroupName "RG-Production"

    Adds Contributor role to specified principal on the resource group
.EXAMPLE
    .\manage-role-assignments.ps1 -Action Audit -ExportPath ".\RoleAudit.csv"

    Audits all role assignments in current subscription and exports to CSV
.EXAMPLE
    .\manage-role-assignments.ps1 -Action Import -ImportPath ".\BulkAssignments.json" -WhatIf

    Preview bulk role assignment import without applying changes
.NOTES
    Author: Azure PowerShell Toolkit#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Direct')]
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory = $true)]
    [ValidateSet('Add', 'Remove', 'Audit', 'Validate', 'Export', 'Import')]
    [string]$Action,

    [Parameter(Mandatory = $false, ParameterSetName = 'Direct')]
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
    [string]$PrincipalId,

    [Parameter(Mandatory = $false)]
    [ValidateSet('User', 'Group', 'ServicePrincipal', 'ManagedIdentity')]
    [string]$PrincipalType = 'User',

    [Parameter(Mandatory = $false, ParameterSetName = 'Direct')]
    [string]$RoleDefinitionName,

    [Parameter(Mandatory = $false, ParameterSetName = 'Direct')]
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
    [string]$RoleDefinitionId,

    [Parameter(Mandatory = $false)]
    [string]$Scope,

    [Parameter(Mandatory = $false)]
    [string]$ManagementGroupId,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveOrphaned,

    [Parameter(Mandatory = $false, ParameterSetName = 'Export')]
    [string]$ExportPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Import')]
    [string]$ImportPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Set default paths if not provided
if ($Action -eq 'Export' -and -not $ExportPath) {
    $ExportPath = ".\RoleAssignments_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

# Initialize logging
$script:LogPath = ".\RoleManagement_$(Get-Date -Format 'yyyyMMdd').log"
$script:ChangeLog = @()

#endregion

#region Helper-Functions
[OutputType([PSCustomObject])]
 {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp [$Level] $Message"

    Add-Content -Path $script:LogPath -Value $logEntry

    switch ($Level) {
        'Info'    { Write-Verbose $Message }
        'Warning' { Write-Warning $Message }
        'Error'   { Write-Error $Message }
        'Success' { Write-Host $Message -ForegroundColor Green }
    }
}

function Initialize-RequiredModules {
    $requiredModules = @('Az.Resources', 'Az.Accounts')

    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-LogEntry "Module $module not found. Installing..." -Level Warning
            try {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                                Write-LogEntry "Successfully installed module: $module" -Level Success
            }
            catch {
                throw "Failed to install required module $module : $_"
            }
        }
        else {
                    }
    }
}

function Get-AzureContext {
    $context = Get-AzContext
    if (-not $context) {
        Write-LogEntry "No Azure context found. Initiating authentication..." -Level Warning
        Connect-AzAccount
        $context = Get-AzContext
    }
    return $context
}

function Resolve-Scope {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ManagementGroupId,
        [string]$ResourceGroupName,
        [string]$ExplicitScope
    )

    if ($ExplicitScope) {
        return $ExplicitScope
    }

    $context = Get-AzureContext

    if ($ManagementGroupId) {
        return "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
    }
    elseif ($ResourceGroupName) {
        return "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroupName"
    }
    else {
        return "/subscriptions/$($context.Subscription.Id)"
    }
}

function Test-PrincipalExists {
    [CmdletBinding(SupportsShouldProcess)]
[string]$PrincipalId)

    try {
        $params = @{
            ObjectId = $PrincipalId
            ErrorAction = 'Stop'
        }

        $principal = Get-AzADUser @params -ErrorAction SilentlyContinue
        if ($principal) { return @{Exists = $true; Type = 'User'; Object = $principal} }

        $principal = Get-AzADGroup @params -ErrorAction SilentlyContinue
        if ($principal) { return @{Exists = $true; Type = 'Group'; Object = $principal} }

        $principal = Get-AzADServicePrincipal @params -ErrorAction SilentlyContinue
        if ($principal) { return @{Exists = $true; Type = 'ServicePrincipal'; Object = $principal} }

        return @{Exists = $false; Type = $null; Object = $null
} catch {
        Write-LogEntry "Error checking principal $PrincipalId : $_" -Level Error
        return @{Exists = $false; Type = $null; Object = $null}
    }
}

#endregion

#region Core-Functions
function Add-RoleAssignment {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$PrincipalId,
        [string]$RoleName,
        [string]$RoleId,
        [string]$Scope
    )

    try {
        # Validate principal exists
        $principalCheck = Test-PrincipalExists -PrincipalId $PrincipalId
        if (-not $principalCheck.Exists) {
            throw "Principal with ID $PrincipalId does not exist or is inaccessible"
        }

        Write-LogEntry "Adding role assignment for $($principalCheck.Type): $PrincipalId" -Level Info

        # Build parameters for role assignment
        $assignmentParams = @{
            ObjectId = $PrincipalId
            Scope = $Scope
        }

        if ($RoleName) {
            $assignmentParams['RoleDefinitionName'] = $RoleName
        }
        elseif ($RoleId) {
            $assignmentParams['RoleDefinitionId'] = $RoleId
        }
        else {
            throw "Either RoleDefinitionName or RoleDefinitionId must be specified"
        }

        # Check if assignment already exists
        $existingAssignments = Get-AzRoleAssignment @assignmentParams -ErrorAction SilentlyContinue
        if ($existingAssignments) {
            Write-LogEntry "Role assignment already exists for principal $PrincipalId" -Level Warning
            return $existingAssignments[0]
        }

        # Create new assignment
        if ($PSCmdlet.ShouldProcess("$PrincipalId at scope $Scope", "Add role $RoleName$RoleId")) {
            $newAssignment = New-AzRoleAssignment @assignmentParams

            $script:ChangeLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action = 'Add'
                PrincipalId = $PrincipalId
                PrincipalType = $principalCheck.Type
                Role = if ($RoleName) { $RoleName } else { $RoleId }
                Scope = $Scope
                Status = 'Success'
            }

            Write-LogEntry "Successfully added role assignment" -Level Success
            return $newAssignment
        
} catch {
        $script:ChangeLog += [PSCustomObject]@{
            Timestamp = Get-Date
            Action = 'Add'
            PrincipalId = $PrincipalId
            Role = if ($RoleName) { $RoleName } else { $RoleId }
            Scope = $Scope
            Status = 'Failed'
            Error = $_.Exception.Message
        }

        Write-LogEntry "Failed to add role assignment: $_" -Level Error
        throw
    }
}

function Remove-RoleAssignment {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$PrincipalId,
        [string]$RoleName,
        [string]$RoleId,
        [string]$Scope
    )

    try {
        Write-LogEntry "Removing role assignment for principal: $PrincipalId" -Level Info

        $removeParams = @{
            ObjectId = $PrincipalId
            Scope = $Scope
        }

        if ($RoleName) {
            $removeParams['RoleDefinitionName'] = $RoleName
        }
        elseif ($RoleId) {
            $removeParams['RoleDefinitionId'] = $RoleId
        }

        # Get existing assignment
        $assignment = Get-AzRoleAssignment @removeParams -ErrorAction SilentlyContinue
        if (-not $assignment) {
            Write-LogEntry "No role assignment found to remove" -Level Warning
            return
        }

        if ($PSCmdlet.ShouldProcess("$PrincipalId at scope $Scope", "Remove role $RoleName$RoleId")) {
            Remove-AzRoleAssignment @removeParams

            $script:ChangeLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action = 'Remove'
                PrincipalId = $PrincipalId
                Role = if ($RoleName) { $RoleName } else { $RoleId }
                Scope = $Scope
                Status = 'Success'
            }

            Write-LogEntry "Successfully removed role assignment" -Level Success
        
} catch {
        $script:ChangeLog += [PSCustomObject]@{
            Timestamp = Get-Date
            Action = 'Remove'
            PrincipalId = $PrincipalId
            Role = if ($RoleName) { $RoleName } else { $RoleId }
            Scope = $Scope
            Status = 'Failed'
            Error = $_.Exception.Message
        }

        Write-LogEntry "Failed to remove role assignment: $_" -Level Error
        throw
    }
}

function Get-RoleAssignmentAudit {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$Scope,
        [switch]$IncludeInherited,
        [switch]$CheckOrphaned
    )

    try {
        Write-LogEntry "Starting role assignment audit for scope: $Scope" -Level Info

        $auditParams = @{
            Scope = $Scope
        }

        if (-not $IncludeInherited) {
            $auditParams['ExpandPrincipalGroups'] = $false
        }

        $assignments = Get-AzRoleAssignment @auditParams

        $auditResults = @()
        $orphanedCount = 0

        foreach ($assignment in $assignments) {
            $auditEntry = [PSCustomObject]@{
                AssignmentId = $assignment.RoleAssignmentId
                PrincipalId = $assignment.ObjectId
                PrincipalType = $assignment.ObjectType
                PrincipalDisplayName = $assignment.DisplayName
                RoleName = $assignment.RoleDefinitionName
                RoleId = $assignment.RoleDefinitionId
                Scope = $assignment.Scope
                CanDelegate = $assignment.CanDelegate
                CreatedOn = $assignment.CreatedOn
                UpdatedOn = $assignment.UpdatedOn
                IsInherited = $assignment.Scope -ne $Scope
                IsOrphaned = $false
                ValidationStatus = 'Valid'
            }

            # Check if principal still exists
            if ($CheckOrphaned) {
                $principalCheck = Test-PrincipalExists -PrincipalId $assignment.ObjectId
                if (-not $principalCheck.Exists) {
                    $auditEntry.IsOrphaned = $true
                    $auditEntry.ValidationStatus = 'Orphaned'
                    $orphanedCount++
                    Write-LogEntry "Found orphaned assignment for principal: $($assignment.ObjectId)" -Level Warning
                }
            }

            $auditResults += $auditEntry
        }

        Write-LogEntry "Audit complete. Found $($assignments.Count) assignments, $orphanedCount orphaned" -Level Info

        return $auditResults
    }
    catch {
        Write-LogEntry "Audit failed: $_" -Level Error
        throw
    }
}

function Export-RoleAssignments {
    [CmdletBinding(SupportsShouldProcess)]

        [array]$Assignments,
        [string]$Path,
        [ValidateSet('CSV', 'JSON', 'HTML')]
        [string]$Format = 'CSV'
    )

    try {
        Write-LogEntry "Exporting $($Assignments.Count) assignments to $Format format" -Level Info

        switch ($Format) {
            'CSV' {
                $Assignments | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            }

            'JSON' {
                $Assignments | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
            }

            'HTML' {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Role Assignment Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; }
        h1 { color: #0078d4; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #0078d4; color: white; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .orphaned { background: #ffe6e6; }
        .inherited { font-style: italic; color: #666; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-box { background: #f0f0f0; padding: 15px; border-radius: 5px; }
        .stat-value { font-size: 24px; font-weight: bold; color: #0078d4; }
    </style>
</head>
<body>
    <h1>Role Assignment Audit Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>

    <div class='stats'>
        <div class='stat-box'>
            <div class='stat-value'>$($Assignments.Count)</div>
            <div>Total Assignments</div>
        </div>
        <div class='stat-box'>
            <div class='stat-value'>$(($Assignments | Where-Object IsOrphaned).Count)</div>
            <div>Orphaned</div>
        </div>
        <div class='stat-box'>
            <div class='stat-value'>$(($Assignments | Select-Object PrincipalId -Unique).Count)</div>
            <div>Unique Principals</div>
        </div>
        <div class='stat-box'>
            <div class='stat-value'>$(($Assignments | Select-Object RoleName -Unique).Count)</div>
            <div>Unique Roles</div>
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th>Principal</th>
                <th>Type</th>
                <th>Role</th>
                <th>Scope</th>
                <th>Status</th>
                <th>Created</th>
            </tr>
        </thead>
        <tbody>
"@
                foreach ($assignment in $Assignments) {
                    $rowClass = if ($assignment.IsOrphaned) { 'orphaned' } elseif ($assignment.IsInherited) { 'inherited' } else { '' }
                    $html += @"
            <tr class='$rowClass'>
                <td>$($assignment.PrincipalDisplayName)</td>
                <td>$($assignment.PrincipalType)</td>
                <td>$($assignment.RoleName)</td>
                <td>$($assignment.Scope)</td>
                <td>$($assignment.ValidationStatus)</td>
                <td>$($assignment.CreatedOn)</td>
            </tr>
"@
                }
                $html += @"
        </tbody>
    </table>
</body>
</html>
"@
                $html | Out-File -FilePath $Path -Encoding UTF8
            }
        }

        Write-LogEntry "Export completed successfully to: $Path" -Level Success
    }
    catch {
        Write-LogEntry "Export failed: $_" -Level Error
        throw
    }
}

function Import-RoleAssignments {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$Path,
        [switch]$ValidateOnly
    )

    try {
        if (-not (Test-Path $Path)) {
            throw "Import file not found: $Path"
        }

        Write-LogEntry "Importing role assignments from: $Path" -Level Info

        $extension = [System.IO.Path]::GetExtension($Path)
        $assignments = switch ($extension) {
            '.csv'  { Import-Csv -Path $Path }
            '.json' { Get-Content -Path $Path -Raw | ConvertFrom-Json }
            default { throw "Unsupported file format: $extension" }
        }

        $results = @{
            Total = $assignments.Count
            Success = 0
            Failed = 0
            Skipped = 0
            Details = @()
        }

        foreach ($assignment in $assignments) {
            try {
                # Validate required fields
                if (-not $assignment.PrincipalId -or -not $assignment.RoleName -or -not $assignment.Scope) {
                    Write-LogEntry "Skipping incomplete assignment entry" -Level Warning
                    $results.Skipped++
                    continue
                }

                # Check if principal exists
                $principalCheck = Test-PrincipalExists -PrincipalId $assignment.PrincipalId
                if (-not $principalCheck.Exists) {
                    Write-LogEntry "Principal not found: $($assignment.PrincipalId)" -Level Warning
                    $results.Failed++
                    $results.Details += [PSCustomObject]@{
                        PrincipalId = $assignment.PrincipalId
                        Status = 'Failed'
                        Reason = 'Principal not found'
                    }
                    continue
                }

                if (-not $ValidateOnly) {
                    $params = @{
                        RoleName = $assignment.RoleName
                        PrincipalId = $assignment.PrincipalId
                        Scope = $assignment.Scope
                    }
                    Add-RoleAssignment @params
                    $results.Success++
                }
                else {
                    Write-LogEntry "Validation passed for: $($assignment.PrincipalId)" -Level Info
                    $results.Success++
                
} catch {
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    PrincipalId = $assignment.PrincipalId
                    Status = 'Failed'
                    Reason = $_.Exception.Message
                }
            }

        Write-LogEntry "Import completed - Success: $($results.Success), Failed: $($results.Failed), Skipped: $($results.Skipped)" -Level Info
        return $results
    }
    catch {
        Write-LogEntry "Import failed: $_" -Level Error
        throw
    }
}

function Remove-OrphanedAssignments {
    [CmdletBinding(SupportsShouldProcess)]
[string]$Scope)

    try {
        Write-LogEntry "Scanning for orphaned role assignments..." -Level Info

        $assignments = Get-RoleAssignmentAudit -Scope $Scope -CheckOrphaned
        $orphaned = $assignments | Where-Object { $_.IsOrphaned }

        if ($orphaned.Count -eq 0) {
            Write-LogEntry "No orphaned assignments found" -Level Info
            return
        }

        Write-LogEntry "Found $($orphaned.Count) orphaned assignments" -Level Warning

        foreach ($assignment in $orphaned) {
            if ($PSCmdlet.ShouldProcess($assignment.PrincipalId, "Remove orphaned assignment")) {
                try {
                    $removeParams = @{
                        ObjectId = $assignment.PrincipalId
                        RoleDefinitionId = $assignment.RoleId
                        Scope = $assignment.Scope
                    }
                    Remove-AzRoleAssignment @removeParams -ErrorAction Stop
                    Write-LogEntry "Removed orphaned assignment: $($assignment.AssignmentId)" -Level Success
                }
                catch {
                    Write-LogEntry "Failed to remove orphaned assignment: $_" -Level Error
                }
            }
        
} catch {
        Write-LogEntry "Orphaned assignment cleanup failed: $_" -Level Error
        throw
    }
}

#endregion

#region Main-Execution
try {
    Write-Host "`nRole Assignment Management Tool" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    # Initialize modules and context
    Initialize-RequiredModules
    $context = Get-AzureContext

    # Resolve scope
    $params = @{
        ExplicitScope = $Scope
        ResourceGroupName = $ResourceGroupName
        ManagementGroupId = $ManagementGroupId
    }
    $targetScope = Resolve-Scope @params

    Write-LogEntry "Operating at scope: $targetScope" -Level Info
    Write-Host "Target scope: $targetScope" -ForegroundColor Yellow

    # Execute requested action
    switch ($Action) {
        'Add' {
            if (-not $PrincipalId -or (-not $RoleDefinitionName -and -not $RoleDefinitionId)) {
                throw "PrincipalId and either RoleDefinitionName or RoleDefinitionId are required for Add action"
            }

            $params = @{
                RoleName = $RoleDefinitionName
                PrincipalId = $PrincipalId
                Scope = $targetScope
                RoleId = $RoleDefinitionId
            }
            $result = Add-RoleAssignment @params

            if ($DetailedOutput) {
                $result | Format-List
            }
        }

        'Remove' {
            if (-not $PrincipalId -or (-not $RoleDefinitionName -and -not $RoleDefinitionId)) {
                throw "PrincipalId and either RoleDefinitionName or RoleDefinitionId are required for Remove action"
            }

            if ($RemoveOrphaned) {
                Remove-OrphanedAssignments -Scope $targetScope
            }
            else {
                $params = @{
                    RoleName = $RoleDefinitionName
                    PrincipalId = $PrincipalId
                    Scope = $targetScope
                    RoleId = $RoleDefinitionId
                }
                Remove-RoleAssignment @params
            }

        'Audit' {
            $auditResults = Get-RoleAssignmentAudit -Scope $targetScope -CheckOrphaned

            if ($ExportPath) {
                $format = switch ([System.IO.Path]::GetExtension($ExportPath)) {
                    '.csv'  { 'CSV' }
                    '.json' { 'JSON' }
                    '.html' { 'HTML' }
                    default { 'CSV' }
                }
                Export-RoleAssignments -Assignments $auditResults -Path $ExportPath -Format $format
            }
            else {
                # Display summary
                Write-Host "`nAudit Summary:" -ForegroundColor Cyan
                Write-Host "Total Assignments: $($auditResults.Count)" -ForegroundColor White
                Write-Host "Orphaned: $(($auditResults | Where-Object IsOrphaned).Count)" -ForegroundColor Yellow
                Write-Host "Inherited: $(($auditResults | Where-Object IsInherited).Count)" -ForegroundColor Gray

                if ($DetailedOutput) {
                    $auditResults | Format-Table -AutoSize
                }
            }
        }

        'Validate' {
            $auditResults = Get-RoleAssignmentAudit -Scope $targetScope -CheckOrphaned
            $issues = $auditResults | Where-Object { $_.ValidationStatus -ne 'Valid' }

            if ($issues.Count -gt 0) {
                Write-Host "`nValidation Issues Found:" -ForegroundColor Yellow
                $issues | Format-Table PrincipalId, PrincipalType, RoleName, ValidationStatus -AutoSize
            }
            else {
                Write-Host "`nAll role assignments are valid" -ForegroundColor Green
            }
        }

        'Export' {
            if (-not $ExportPath) {
                $ExportPath = ".\RoleAssignments_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            }

            $assignments = Get-RoleAssignmentAudit -Scope $targetScope -CheckOrphaned
            $format = switch ([System.IO.Path]::GetExtension($ExportPath)) {
                '.csv'  { 'CSV' }
                '.json' { 'JSON' }
                '.html' { 'HTML' }
                default { 'CSV' }
            }

            Export-RoleAssignments -Assignments $assignments -Path $ExportPath -Format $format
            Write-Host "Exported $($assignments.Count) assignments to: $ExportPath" -ForegroundColor Green
        }

        'Import' {
            if (-not $ImportPath) {
                throw "ImportPath is required for Import action"
            }

            $validateOnly = -not $Force -and -not $PSCmdlet.ShouldContinue(
                "Import and apply role assignments from $ImportPath?",
                "Confirm Import"
            )

            $importResults = Import-RoleAssignments -Path $ImportPath -ValidateOnly:$validateOnly

            Write-Host "`nImport Results:" -ForegroundColor Cyan
            Write-Host "Total: $($importResults.Total)" -ForegroundColor White
            Write-Host "Success: $($importResults.Success)" -ForegroundColor Green
            Write-Host "Failed: $($importResults.Failed)" -ForegroundColor Red
            Write-Host "Skipped: $($importResults.Skipped)" -ForegroundColor Yellow

            if ($DetailedOutput -and $importResults.Details.Count -gt 0) {
                Write-Host "`nDetails:" -ForegroundColor Cyan
                $importResults.Details | Format-Table -AutoSize
            }
        }
    }

    # Export change log if changes were made
    if ($script:ChangeLog.Count -gt 0) {
        $changeLogPath = ".\RoleChanges_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $script:ChangeLog | Export-Csv -Path $changeLogPath -NoTypeInformation
        Write-Host "`nChange log exported to: $changeLogPath" -ForegroundColor Cyan
    }

    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    Write-LogEntry "Operation failed: $_" -Level Error
    Write-Error $_
    throw
}
finally {
    # Cleanup
    $ProgressPreference = 'Continue'
}

#endregion

