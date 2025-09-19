#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Assigns Azure policies to subscriptions, resource groups, or management groups with comprehensive configuration options.

.DESCRIPTION
    This script provides comprehensive Azure Policy assignment capabilities with support for various scopes,
    parameter handling, identity configuration, and detailed monitoring. It supports both built-in and
    custom policies with flexible parameter management and comprehensive logging.

.PARAMETER PolicyDefinitionId
    The resource ID of the policy definition to assign.

.PARAMETER PolicyName
    The name of a built-in policy definition to assign (alternative to PolicyDefinitionId).

.PARAMETER AssignmentName
    Name for the policy assignment. If not provided, generates one based on policy name.

.PARAMETER DisplayName
    Display name for the policy assignment.

.PARAMETER Description
    Description for the policy assignment.

.PARAMETER Scope
    The scope for the policy assignment. Can be subscription, resource group, or management group.
    Format: /subscriptions/{id}, /subscriptions/{id}/resourceGroups/{name}, or /providers/Microsoft.Management/managementGroups/{id}

.PARAMETER SubscriptionId
    Azure subscription ID for the assignment scope.

.PARAMETER ResourceGroupName
    Resource group name for resource group-scoped assignments.

.PARAMETER ManagementGroupId
    Management group ID for management group-scoped assignments.

.PARAMETER Parameters
    Policy parameters as hashtable or path to JSON file.

.PARAMETER NotScopes
    Array of scopes to exclude from the policy assignment.

.PARAMETER Location
    Azure region for the policy assignment identity. Required when using managed identity.

.PARAMETER SystemAssignedIdentity
    Use system-assigned managed identity for policy enforcement.

.PARAMETER UserAssignedIdentityId
    Resource ID of user-assigned managed identity for policy enforcement.

.PARAMETER PolicySetDefinitionId
    Resource ID of policy set definition (initiative) to assign instead of individual policy.

.PARAMETER EnforcementMode
    Policy enforcement mode: Default, DoNotEnforce.

.PARAMETER NonComplianceMessages
    Array of non-compliance messages for the policy assignment.

.PARAMETER WhatIf
    Show what would be assigned without actually creating the assignment.

.PARAMETER Force
    Force the assignment even if there are validation warnings.

.PARAMETER LogPath
    Path to store detailed logs. If not provided, logs to default location.

.EXAMPLE
    .\assign-policy.ps1 -PolicyName "Audit VMs without managed disks" -SubscriptionId "12345678-1234-1234-1234-123456789012"

.EXAMPLE
    .\assign-policy.ps1 -PolicyDefinitionId "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d" -ResourceGroupName "MyRG" -SubscriptionId "12345678-1234-1234-1234-123456789012"

.EXAMPLE
    .\assign-policy.ps1 -PolicyName "Require tag and its value" -Parameters @{tagName="Environment"; tagValue="Production"} -SystemAssignedIdentity -Location "East US"

.NOTES
    File Name      : assign-policy.ps1
    Author         : Wes Ellis (wes@wesellis.com)
    Created        : 2024-11-15
    Prerequisites  : Azure PowerShell module, appropriate Azure permissions
    Version        : 1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(ParameterSetName = "ByDefinitionId", Mandatory = $true, HelpMessage = "Policy definition resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyDefinitionId,

    [Parameter(ParameterSetName = "ByPolicyName", Mandatory = $true, HelpMessage = "Built-in policy definition name")]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyName,

    [Parameter(HelpMessage = "Policy assignment name")]
    [ValidateLength(1, 128)]
    [string]$AssignmentName,

    [Parameter(HelpMessage = "Policy assignment display name")]
    [ValidateLength(1, 128)]
    [string]$DisplayName,

    [Parameter(HelpMessage = "Policy assignment description")]
    [ValidateLength(1, 512)]
    [string]$Description,

    [Parameter(HelpMessage = "Policy assignment scope")]
    [ValidatePattern('^/(subscriptions/[^/]+|providers/Microsoft\.Management/managementGroups/[^/]+)(/resourceGroups/[^/]+)?$')]
    [string]$Scope,

    [Parameter(HelpMessage = "Azure subscription ID")]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId,

    [Parameter(HelpMessage = "Resource group name for assignment scope")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(HelpMessage = "Management group ID for assignment scope")]
    [ValidateNotNullOrEmpty()]
    [string]$ManagementGroupId,

    [Parameter(HelpMessage = "Policy parameters as hashtable or JSON file path")]
    [object]$Parameters,

    [Parameter(HelpMessage = "Scopes to exclude from policy assignment")]
    [string[]]$NotScopes,

    [Parameter(HelpMessage = "Azure region for managed identity")]
    [ValidateNotNullOrEmpty()]
    [string]$Location = "East US",

    [Parameter(HelpMessage = "Use system-assigned managed identity")]
    [switch]$SystemAssignedIdentity,

    [Parameter(HelpMessage = "User-assigned managed identity resource ID")]
    [ValidatePattern('^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[^/]+$')]
    [string]$UserAssignedIdentityId,

    [Parameter(HelpMessage = "Policy set definition ID (initiative)")]
    [ValidateNotNullOrEmpty()]
    [string]$PolicySetDefinitionId,

    [Parameter(HelpMessage = "Policy enforcement mode")]
    [ValidateSet("Default", "DoNotEnforce")]
    [string]$EnforcementMode = "Default",

    [Parameter(HelpMessage = "Non-compliance messages")]
    [hashtable[]]$NonComplianceMessages,

    [Parameter(HelpMessage = "Show what would be assigned without creating")]
    [switch]$WhatIf,

    [Parameter(HelpMessage = "Force assignment even with warnings")]
    [switch]$Force,

    [Parameter(HelpMessage = "Path for detailed logging")]
    [ValidateScript({ Test-Path (Split-Path $_ -Parent) })]
    [string]$LogPath
)

#region Functions

#Requires -Version 5.1
#Requires -Modules Az.Resources, Az.Accounts, Az.Profile

# Initialize logging
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if (-not $LogPath) {
    $LogPath = Join-Path $env:TEMP "assign-policy_$timestamp.log"
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )

    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logEntry

    switch ($Level) {
        'Error' { Write-Error $Message }
        'Warning' { Write-Warning $Message }
        'Debug' { Write-Debug $Message }
        default { Write-Host $Message }
    }
}

function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if (-not $context) {
            throw "Not connected to Azure"
        }
        Write-Log "Connected to Azure as $($context.Account.Id)"
        return $true
    }
    catch {
        Write-Log "Azure connection test failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-PolicyDefinition {
    param(
        [string]$DefinitionId,
        [string]$PolicyName
    )

    try {
        if ($DefinitionId) {
            Write-Log "Retrieving policy definition by ID: $DefinitionId"
            $policy = Get-AzPolicyDefinition -Id $DefinitionId
        }
        elseif ($PolicyName) {
            Write-Log "Searching for built-in policy: $PolicyName"
            $policies = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -eq $PolicyName -or $_.Name -eq $PolicyName }

            if ($policies.Count -eq 0) {
                throw "No policy found with name '$PolicyName'"
            }
            elseif ($policies.Count -gt 1) {
                Write-Log "Multiple policies found with name '$PolicyName'. Using the first match."
            }

            $policy = $policies[0]
        }
        else {
            throw "Either PolicyDefinitionId or PolicyName must be provided"
        }

        Write-Log "Found policy: $($policy.Properties.DisplayName) (ID: $($policy.ResourceId))"
        return $policy
    }
    catch {
        Write-Log "Failed to get policy definition: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Resolve-AssignmentScope {
    param(
        [string]$Scope,
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [string]$ManagementGroupId
    )

    if ($Scope) {
        Write-Log "Using provided scope: $Scope"
        return $Scope
    }

    if ($ManagementGroupId) {
        $resolvedScope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
        Write-Log "Using management group scope: $resolvedScope"
        return $resolvedScope
    }

    if ($SubscriptionId) {
        if ($ResourceGroupName) {
            $resolvedScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"
            Write-Log "Using resource group scope: $resolvedScope"
        }
        else {
            $resolvedScope = "/subscriptions/$SubscriptionId"
            Write-Log "Using subscription scope: $resolvedScope"
        }
        return $resolvedScope
    }

    # Use current subscription context
    $context = Get-AzContext
    if ($context -and $context.Subscription) {
        $resolvedScope = "/subscriptions/$($context.Subscription.Id)"
        Write-Log "Using current subscription scope: $resolvedScope"
        return $resolvedScope
    }

    throw "Unable to determine assignment scope. Please provide Scope, SubscriptionId, or ensure you have an active Azure context."
}

function ConvertTo-PolicyParameters {
    param([object]$InputParameters)

    if (-not $InputParameters) {
        return $null
    }

    if ($InputParameters -is [string] -and (Test-Path $InputParameters)) {
        try {
            $paramContent = Get-Content $InputParameters -Raw | ConvertFrom-Json
            Write-Log "Loaded parameters from file: $InputParameters"
            return $paramContent
        }
        catch {
            Write-Log "Failed to parse parameter file '$InputParameters': $($_.Exception.Message)" -Level Error
            throw
        }
    }
    elseif ($InputParameters -is [hashtable]) {
        Write-Log "Using provided parameter hashtable"
        return $InputParameters
    }
    else {
        throw "Parameters must be a hashtable or path to a JSON file"
    }
}

function New-PolicyAssignmentObject {
    param(
        [object]$PolicyDefinition,
        [string]$Name,
        [string]$DisplayName,
        [string]$Description,
        [string]$Scope,
        [object]$Parameters,
        [string[]]$NotScopes,
        [string]$Location,
        [string]$EnforcementMode,
        [hashtable[]]$NonComplianceMessages,
        [bool]$UseSystemIdentity,
        [string]$UserAssignedIdentityId
    )

    try {
        $assignmentParams = @{
            PolicyDefinition = $PolicyDefinition
            Name = $Name
            Scope = $Scope
            EnforcementMode = $EnforcementMode
        }

        if ($DisplayName) {
            $assignmentParams.DisplayName = $DisplayName
        }

        if ($Description) {
            $assignmentParams.Description = $Description
        }

        if ($Parameters) {
            $assignmentParams.PolicyParameter = $Parameters
        }

        if ($NotScopes -and $NotScopes.Count -gt 0) {
            $assignmentParams.NotScope = $NotScopes
        }

        if ($NonComplianceMessages -and $NonComplianceMessages.Count -gt 0) {
            $assignmentParams.NonComplianceMessage = $NonComplianceMessages
        }

        # Configure identity if policy requires it
        if ($PolicyDefinition.Properties.PolicyRule.then.details.roleDefinitionIds) {
            if (-not $Location) {
                throw "Location is required when assigning policies that require managed identity"
            }

            $assignmentParams.Location = $Location

            if ($UserAssignedIdentityId) {
                $assignmentParams.IdentityType = "UserAssigned"
                $assignmentParams.IdentityId = $UserAssignedIdentityId
            }
            elseif ($UseSystemIdentity) {
                $assignmentParams.IdentityType = "SystemAssigned"
            }
            else {
                Write-Log "Policy requires managed identity but none specified. Using system-assigned identity." -Level Warning
                $assignmentParams.IdentityType = "SystemAssigned"
            }
        }

        return $assignmentParams
    }
    catch {
        Write-Log "Failed to create policy assignment parameters: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Test-PolicyAssignment {
    param(
        [string]$Name,
        [string]$Scope
    )

    try {
        $existing = Get-AzPolicyAssignment -Name $Name -Scope $Scope -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Log "Policy assignment '$Name' already exists in scope '$Scope'" -Level Warning
            return $existing
        }
        return $null
    }
    catch {
        return $null
    }
}

# Main execution
try {
    Write-Log "Starting policy assignment process..."

    # Test Azure connection
    if (-not (Test-AzureConnection)) {
        throw "Azure connection required. Please run Connect-AzAccount first."
    }

    # Set subscription context if provided
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-Log "Set subscription context: $SubscriptionId"
    }

    # Resolve assignment scope
    $assignmentScope = Resolve-AssignmentScope -Scope $Scope -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -ManagementGroupId $ManagementGroupId

    # Get policy definition
    if ($PolicySetDefinitionId) {
        Write-Log "Retrieving policy set definition: $PolicySetDefinitionId"
        $policyDefinition = Get-AzPolicySetDefinition -Id $PolicySetDefinitionId
        Write-Log "Found policy set: $($policyDefinition.Properties.DisplayName)"
    }
    else {
        $policyDefinition = Get-PolicyDefinition -DefinitionId $PolicyDefinitionId -PolicyName $PolicyName
    }

    # Generate assignment name if not provided
    if (-not $AssignmentName) {
        $baseName = if ($PolicyName) { $PolicyName } else { $policyDefinition.Name }
        $AssignmentName = "$baseName-assignment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $AssignmentName = $AssignmentName -replace '[^a-zA-Z0-9\-_]', '-'
        $AssignmentName = $AssignmentName.Substring(0, [Math]::Min($AssignmentName.Length, 64))
        Write-Log "Generated assignment name: $AssignmentName"
    }

    # Generate display name if not provided
    if (-not $DisplayName) {
        $DisplayName = "Assignment: $($policyDefinition.Properties.DisplayName)"
        Write-Log "Generated display name: $DisplayName"
    }

    # Check for existing assignment
    $existingAssignment = Test-PolicyAssignment -Name $AssignmentName -Scope $assignmentScope
    if ($existingAssignment -and -not $Force) {
        throw "Policy assignment '$AssignmentName' already exists. Use -Force to overwrite."
    }

    # Process parameters
    $policyParameters = ConvertTo-PolicyParameters -InputParameters $Parameters
    if ($policyParameters) {
        Write-Log "Processed policy parameters"
    }

    # Validate identity configuration
    if ($SystemAssignedIdentity -and $UserAssignedIdentityId) {
        throw "Cannot specify both SystemAssignedIdentity and UserAssignedIdentityId"
    }

    # Create assignment parameters
    $assignmentParams = New-PolicyAssignmentObject -PolicyDefinition $policyDefinition -Name $AssignmentName -DisplayName $DisplayName -Description $Description -Scope $assignmentScope -Parameters $policyParameters -NotScopes $NotScopes -Location $Location -EnforcementMode $EnforcementMode -NonComplianceMessages $NonComplianceMessages -UseSystemIdentity $SystemAssignedIdentity -UserAssignedIdentityId $UserAssignedIdentityId

    # WhatIf processing
    if ($WhatIf) {
        Write-Log "WhatIf mode: Would create policy assignment with the following configuration:" -Level Warning
        Write-Log "  Assignment Name: $AssignmentName"
        Write-Log "  Display Name: $DisplayName"
        Write-Log "  Policy: $($policyDefinition.Properties.DisplayName)"
        Write-Log "  Scope: $assignmentScope"
        Write-Log "  Enforcement Mode: $EnforcementMode"
        if ($assignmentParams.IdentityType) {
            Write-Log "  Identity Type: $($assignmentParams.IdentityType)"
        }
        if ($policyParameters) {
            Write-Log "  Parameters: Yes ($($policyParameters.Count) parameters)"
        }
        if ($NotScopes) {
            Write-Log "  Exclusions: $($NotScopes.Count) not-scopes"
        }
        return
    }

    # Remove existing assignment if forcing
    if ($existingAssignment -and $Force) {
        Write-Log "Removing existing assignment: $AssignmentName"
        Remove-AzPolicyAssignment -Name $AssignmentName -Scope $assignmentScope -Force
        Start-Sleep -Seconds 5  # Allow time for cleanup
    }

    # Create policy assignment
    Write-Log "Creating policy assignment '$AssignmentName'..."
    $assignment = New-AzPolicyAssignment @assignmentParams

    Write-Log "Policy assignment created successfully!"
    Write-Log "Assignment ID: $($assignment.ResourceId)"
    Write-Log "Assignment Name: $($assignment.Name)"
    Write-Log "Policy: $($assignment.Properties.PolicyDefinitionId)"
    Write-Log "Scope: $($assignment.Properties.Scope)"
    Write-Log "Enforcement Mode: $($assignment.Properties.EnforcementMode)"

    if ($assignment.Identity) {
        Write-Log "Identity Type: $($assignment.Identity.Type)"
        if ($assignment.Identity.PrincipalId) {
            Write-Log "Principal ID: $($assignment.Identity.PrincipalId)"
        }
    }

    # Return assignment object
    return $assignment
}
catch {
    $errorMessage = "Policy assignment failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level Error
    throw $_
}
finally {
    Write-Log "Log file saved to: $LogPath"
}


#endregion
