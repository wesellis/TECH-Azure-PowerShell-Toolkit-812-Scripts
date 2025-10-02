#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Manages RBAC role assignments within subscriptions, management groups, or resource groups

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    RBAC assignments at various scopes. Supports bulk operations, role definition management,
    and compliance reporting with full audit trail capabilities.
.parameter Action
    The action to perform: Add, Remove, Audit, Validate, Export, Import
.parameter PrincipalId
    Object ID of the user, group, service principal, or managed identity
.parameter PrincipalType
    Type of principal: User, Group, ServicePrincipal, ManagedIdentity
.parameter RoleDefinitionName
    Name of the built-in or custom role (e.g., 'Contributor', 'Reader', 'Owner')
.parameter RoleDefinitionId
    GUID of the role definition (alternative to RoleDefinitionName)
.parameter Scope
    Scope at which to apply the role assignment (subscription/resource group/resource)
.parameter ManagementGroupId
    Management group ID for cross-subscription operations
.parameter ResourceGroupName
    Target resource group name for scoped assignments
.parameter RemoveOrphaned
    Remove role assignments for deleted principals
.parameter ExportPath
    Path to export audit results or role assignments
.parameter ImportPath
    Path to import bulk role assignments from CSV/JSON
.parameter WhatIf
    Preview changes without applying them
.parameter Confirm
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
    Author: Azure PowerShell Toolkit

[parameter(Mandatory = $true)]
    [ValidateSet('Add', 'Remove', 'Audit', 'Validate', 'Export', 'Import')]
    [string]$Action,

    [parameter(Mandatory = $false, ParameterSetName = 'Direct')]
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
    [string]$PrincipalId,

    [parameter(Mandatory = $false)]
    [ValidateSet('User', 'Group', 'ServicePrincipal', 'ManagedIdentity')]
    [string]$PrincipalType = 'User',

    [parameter(Mandatory = $false, ParameterSetName = 'Direct')]
    [string]$RoleDefinitionName,

    [parameter(Mandatory = $false, ParameterSetName = 'Direct')]
    [ValidatePattern('^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')]
    [string]$RoleDefinitionId,

    [parameter(Mandatory = $false)]
    [string]$Scope,

    [parameter(Mandatory = $false)]
    [string]$ManagementGroupId,

    [parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [parameter(Mandatory = $false)]
    [switch]$RemoveOrphaned,

    [parameter(Mandatory = $false, ParameterSetName = 'Export')]
    [string]$ExportPath,

    [parameter(Mandatory = $false, ParameterSetName = 'Import')]
    [string]$ImportPath,

    [parameter(Mandatory = $false)]
    [switch]$Force,

    [parameter(Mandatory = $false)]
    [switch]$DetailedOutput
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($Action -eq 'Export' -and -not $ExportPath) {
    $ExportPath = ".\RoleAssignments_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

$script:LogPath = ".\RoleManagement_$(Get-Date -Format 'yyyyMMdd').log"
$script:ChangeLog = @()


function Write-Log {
    [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$timestamp [$Level] $Message"

    Add-Content -Path $script:LogPath -Value $LogEntry

    switch ($Level) {
        'Info'    { write-Verbose $Message }
        'Warning' { write-Warning $Message }
        'Error'   { write-Error $Message }
        'Success' { Write-Output $Message -ForegroundColor Green }
    }
}

function Initialize-RequiredModules {
    $RequiredModules = @('Az.Resources', 'Az.Accounts')

    foreach ($module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            write-LogEntry "Module $module not found. Installing..." -Level Warning
            try {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                                write-LogEntry "Successfully installed module: $module" -Level Success
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
        write-LogEntry "No Azure context found. Initiating authentication..." -Level Warning
        Connect-AzAccount
        $context = Get-AzContext
    }
    return $context
}

function Resolve-Scope {
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
        write-LogEntry "Error checking principal $PrincipalId : $_" -Level Error
        return @{Exists = $false; Type = $null; Object = $null}
    }
}


function Add-RoleAssignment {
    [string]$PrincipalId,
        [string]$RoleName,
        [string]$RoleId,
        [string]$Scope
    )

    try {
        $PrincipalCheck = Test-PrincipalExists -PrincipalId $PrincipalId
        if (-not $PrincipalCheck.Exists) {
            throw "Principal with ID $PrincipalId does not exist or is inaccessible"
        }

        write-LogEntry "Adding role assignment for $($PrincipalCheck.Type): $PrincipalId" -Level Info

        $AssignmentParams = @{
            ObjectId = $PrincipalId
            Scope = $Scope
        }

        if ($RoleName) {
            $AssignmentParams['RoleDefinitionName'] = $RoleName
        }
        elseif ($RoleId) {
            $AssignmentParams['RoleDefinitionId'] = $RoleId
        }
        else {
            throw "Either RoleDefinitionName or RoleDefinitionId must be specified"
        }

        $ExistingAssignments = Get-AzRoleAssignment @assignmentParams -ErrorAction SilentlyContinue
        if ($ExistingAssignments) {
            write-LogEntry "Role assignment already exists for principal $PrincipalId" -Level Warning
            return $ExistingAssignments[0]
        }

        if ($PSCmdlet.ShouldProcess("$PrincipalId at scope $Scope", "Add role $RoleName$RoleId")) {
            $NewAssignment = New-AzRoleAssignment @assignmentParams

            $script:ChangeLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action = 'Add'
                PrincipalId = $PrincipalId
                PrincipalType = $PrincipalCheck.Type
                Role = if ($RoleName) { $RoleName } else { $RoleId }
                Scope = $Scope
                Status = 'Success'
            }

            write-LogEntry "Successfully added role assignment" -Level Success
            return $NewAssignment

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

        write-LogEntry "Failed to add role assignment: $_" -Level Error
        throw
    }
}

function Remove-RoleAssignment {
    [string]$PrincipalId,
        [string]$RoleName,
        [string]$RoleId,
        [string]$Scope
    )

    try {
        write-LogEntry "Removing role assignment for principal: $PrincipalId" -Level Info

        $RemoveParams = @{
            ObjectId = $PrincipalId
            Scope = $Scope
        }

        if ($RoleName) {
            $RemoveParams['RoleDefinitionName'] = $RoleName
        }
        elseif ($RoleId) {
            $RemoveParams['RoleDefinitionId'] = $RoleId
        }

        $assignment = Get-AzRoleAssignment @removeParams -ErrorAction SilentlyContinue
        if (-not $assignment) {
            write-LogEntry "No role assignment found to remove" -Level Warning
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

            write-LogEntry "Successfully removed role assignment" -Level Success

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

        write-LogEntry "Failed to remove role assignment: $_" -Level Error
        throw
    }
}

function Get-RoleAssignmentAudit {
    [string]$Scope,
        [switch]$IncludeInherited,
        [switch]$CheckOrphaned
    )

    try {
        write-LogEntry "Starting role assignment audit for scope: $Scope" -Level Info

        $AuditParams = @{
            Scope = $Scope
        }

        if (-not $IncludeInherited) {
            $AuditParams['ExpandPrincipalGroups'] = $false
        }

        $assignments = Get-AzRoleAssignment @auditParams

        $AuditResults = @()
        $OrphanedCount = 0

        foreach ($assignment in $assignments) {
            $AuditEntry = [PSCustomObject]@{
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

            if ($CheckOrphaned) {
                $PrincipalCheck = Test-PrincipalExists -PrincipalId $assignment.ObjectId
                if (-not $PrincipalCheck.Exists) {
                    $AuditEntry.IsOrphaned = $true
                    $AuditEntry.ValidationStatus = 'Orphaned'
                    $OrphanedCount++
                    write-LogEntry "Found orphaned assignment for principal: $($assignment.ObjectId)" -Level Warning
                }
            }

            $AuditResults += $AuditEntry
        }

        write-LogEntry "Audit complete. Found $($assignments.Count) assignments, $OrphanedCount orphaned" -Level Info

        return $AuditResults
    }
    catch {
        write-LogEntry "Audit failed: $_" -Level Error
        throw
    }
}

function Export-RoleAssignments {
    [array]$Assignments,
        [string]$Path,
        [ValidateSet('CSV', 'JSON', 'HTML')]
        [string]$Format = 'CSV'
    )

    try {
        write-LogEntry "Exporting $($Assignments.Count) assignments to $Format format" -Level Info

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
        h1 { color:
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background:
        td { padding: 8px; border-bottom: 1px solid
        tr:hover { background:
        .orphaned { background:
        .inherited { font-style: italic; color:
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-box { background:
        .stat-value { font-size: 24px; font-weight: bold; color:
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
                    $RowClass = if ($assignment.IsOrphaned) { 'orphaned' } elseif ($assignment.IsInherited) { 'inherited' } else { '' }
                    $html += @"
            <tr class='$RowClass'>
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

        write-LogEntry "Export completed successfully to: $Path" -Level Success
    }
    catch {
        write-LogEntry "Export failed: $_" -Level Error
        throw
    }
}

function Import-RoleAssignments {
    [string]$Path,
        [switch]$ValidateOnly
    )

    try {
        if (-not (Test-Path $Path)) {
            throw "Import file not found: $Path"
        }

        write-LogEntry "Importing role assignments from: $Path" -Level Info

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
                if (-not $assignment.PrincipalId -or -not $assignment.RoleName -or -not $assignment.Scope) {
                    write-LogEntry "Skipping incomplete assignment entry" -Level Warning
                    $results.Skipped++
                    continue
                }

                $PrincipalCheck = Test-PrincipalExists -PrincipalId $assignment.PrincipalId
                if (-not $PrincipalCheck.Exists) {
                    write-LogEntry "Principal not found: $($assignment.PrincipalId)" -Level Warning
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
                    write-LogEntry "Validation passed for: $($assignment.PrincipalId)" -Level Info
                    $results.Success++

} catch {
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    PrincipalId = $assignment.PrincipalId
                    Status = 'Failed'
                    Reason = $_.Exception.Message
                }
            }

        write-LogEntry "Import completed - Success: $($results.Success), Failed: $($results.Failed), Skipped: $($results.Skipped)" -Level Info
        return $results
    }
    catch {
        write-LogEntry "Import failed: $_" -Level Error
        throw
    }
}

function Remove-OrphanedAssignments {
    [string]$Scope)

    try {
        write-LogEntry "Scanning for orphaned role assignments..." -Level Info

        $assignments = Get-RoleAssignmentAudit -Scope $Scope -CheckOrphaned
        $orphaned = $assignments | Where-Object { $_.IsOrphaned }

        if ($orphaned.Count -eq 0) {
            write-LogEntry "No orphaned assignments found" -Level Info
            return
        }

        write-LogEntry "Found $($orphaned.Count) orphaned assignments" -Level Warning

        foreach ($assignment in $orphaned) {
            if ($PSCmdlet.ShouldProcess($assignment.PrincipalId, "Remove orphaned assignment")) {
                try {
                    $RemoveParams = @{
                        ObjectId = $assignment.PrincipalId
                        RoleDefinitionId = $assignment.RoleId
                        Scope = $assignment.Scope
                    }
                    Remove-AzRoleAssignment @removeParams -ErrorAction Stop
                    write-LogEntry "Removed orphaned assignment: $($assignment.AssignmentId)" -Level Success
                }
                catch {
                    write-LogEntry "Failed to remove orphaned assignment: $_" -Level Error
                }
            }

} catch {
        write-LogEntry "Orphaned assignment cleanup failed: $_" -Level Error
        throw
    }
}


try {
    Write-Host "`nRole Assignment Management Tool" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green

    Initialize-RequiredModules
    $context = Get-AzureContext

    $params = @{
        ExplicitScope = $Scope
        ResourceGroupName = $ResourceGroupName
        ManagementGroupId = $ManagementGroupId
    }
    $TargetScope = Resolve-Scope @params

    write-LogEntry "Operating at scope: $TargetScope" -Level Info
    Write-Host "Target scope: $TargetScope" -ForegroundColor Green

    switch ($Action) {
        'Add' {
            if (-not $PrincipalId -or (-not $RoleDefinitionName -and -not $RoleDefinitionId)) {
                throw "PrincipalId and either RoleDefinitionName or RoleDefinitionId are required for Add action"
            }

            $params = @{
                RoleName = $RoleDefinitionName
                PrincipalId = $PrincipalId
                Scope = $TargetScope
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
                Remove-OrphanedAssignments -Scope $TargetScope
            }
            else {
                $params = @{
                    RoleName = $RoleDefinitionName
                    PrincipalId = $PrincipalId
                    Scope = $TargetScope
                    RoleId = $RoleDefinitionId
                }
                Remove-RoleAssignment @params
            }

        'Audit' {
            $AuditResults = Get-RoleAssignmentAudit -Scope $TargetScope -CheckOrphaned

            if ($ExportPath) {
                $format = switch ([System.IO.Path]::GetExtension($ExportPath)) {
                    '.csv'  { 'CSV' }
                    '.json' { 'JSON' }
                    '.html' { 'HTML' }
                    default { 'CSV' }
                }
                Export-RoleAssignments -Assignments $AuditResults -Path $ExportPath -Format $format
            }
            else {
                Write-Host "`nAudit Summary:" -ForegroundColor Green
                Write-Host "Total Assignments: $($AuditResults.Count)" -ForegroundColor Green
                Write-Host "Orphaned: $(($AuditResults | Where-Object IsOrphaned).Count)" -ForegroundColor Green
                Write-Host "Inherited: $(($AuditResults | Where-Object IsInherited).Count)" -ForegroundColor Green

                if ($DetailedOutput) {
                    $AuditResults | Format-Table -AutoSize
                }
            }
        }

        'Validate' {
            $AuditResults = Get-RoleAssignmentAudit -Scope $TargetScope -CheckOrphaned
            $issues = $AuditResults | Where-Object { $_.ValidationStatus -ne 'Valid' }

            if ($issues.Count -gt 0) {
                Write-Host "`nValidation Issues Found:" -ForegroundColor Green
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

            $assignments = Get-RoleAssignmentAudit -Scope $TargetScope -CheckOrphaned
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

            $ValidateOnly = -not $Force -and -not $PSCmdlet.ShouldContinue(
                "Import and apply role assignments from $ImportPath?",
                "Confirm Import"
            )

            $ImportResults = Import-RoleAssignments -Path $ImportPath -ValidateOnly:$ValidateOnly

            Write-Host "`nImport Results:" -ForegroundColor Green
            Write-Host "Total: $($ImportResults.Total)" -ForegroundColor Green
            Write-Host "Success: $($ImportResults.Success)" -ForegroundColor Green
            Write-Host "Failed: $($ImportResults.Failed)" -ForegroundColor Green
            Write-Host "Skipped: $($ImportResults.Skipped)" -ForegroundColor Green

            if ($DetailedOutput -and $ImportResults.Details.Count -gt 0) {
                Write-Host "`nDetails:" -ForegroundColor Green
                $ImportResults.Details | Format-Table -AutoSize
            }
        }
    }

    if ($script:ChangeLog.Count -gt 0) {
        $ChangeLogPath = ".\RoleChanges_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $script:ChangeLog | Export-Csv -Path $ChangeLogPath -NoTypeInformation
        Write-Host "`nChange log exported to: $ChangeLogPath" -ForegroundColor Green
    }

    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    write-LogEntry "Operation failed: $_" -Level Error
    write-Error $_
    throw
}
finally {
    $ProgressPreference = 'Continue'`n}
