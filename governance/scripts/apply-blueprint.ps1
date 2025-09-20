#Requires -Version 5.1
#Requires -Module Az.Blueprint
<#
.SYNOPSIS
    apply blueprint
.DESCRIPTION
    apply blueprint operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Applies an Azure Blueprint to a subscription with

    This script applies an Azure Blueprint to a specified subscription, providing
    configuration options, validation, and monitoring capabilities. It supports both published
    and draft blueprints with flexible parameter handling and detailed logging.
.PARAMETER BlueprintName
    The name of the Azure Blueprint to apply.
.PARAMETER SubscriptionId
    The Azure subscription ID where the blueprint will be applied.
    If not provided, uses the current subscription context.
.PARAMETER BlueprintVersion
    The version of the blueprint to apply. If not specified, uses the latest published version.
.PARAMETER AssignmentName
    Name for the blueprint assignment. If not provided, generates one based on blueprint name and timestamp.
.PARAMETER Location
    Azure region for the blueprint assignment. Defaults to 'East US'.
.PARAMETER Parameters
    Hashtable of parameters to pass to the blueprint. Can also be a path to a JSON file.
.PARAMETER ResourceGroupNames
    Hashtable mapping resource group placeholder names to actual resource group names.
.PARAMETER SystemAssignedIdentity
    Use system-assigned managed identity for the blueprint assignment.
.PARAMETER UserAssignedIdentityId
    Resource ID of a user-assigned managed identity to use for the blueprint assignment.
.PARAMETER Wait
    Wait for the blueprint assignment to complete before returning.
.PARAMETER TimeoutMinutes
    Maximum time to wait for blueprint assignment completion (default: 30 minutes).
.PARAMETER WhatIf
    Show what would be deployed without actually applying the blueprint.
.PARAMETER Force
    Force the blueprint application even if there are validation warnings.
.PARAMETER LogPath
    Path to store detailed logs. If not provided, logs to default location.

    .\apply-blueprint.ps1 -BlueprintName "MyBlueprint" -SubscriptionId "12345678-1234-1234-1234-123456789012"

    .\apply-blueprint.ps1 -BlueprintName "MyBlueprint" -Parameters @{location="westus2"; environment="prod"} -Wait

    .\apply-blueprint.ps1 -BlueprintName "MyBlueprint" -Parameters "C:\params.json" -SystemAssignedIdentity -WhatIf

    File Name      : apply-blueprint.ps1
    Author         : Azure PowerShell Toolkit
    Created        : 2024-11-15
    Prerequisites  : Azure PowerShell module, appropriate Azure permissions
    Version        : 1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Name of the Azure Blueprint to apply")]
    [ValidateNotNullOrEmpty()]
    [string]$BlueprintName,

    [Parameter(HelpMessage = "Azure subscription ID")]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId,

    [Parameter(HelpMessage = "Blueprint version to apply")]
    [ValidateNotNullOrEmpty()]
    [string]$BlueprintVersion,

    [Parameter(HelpMessage = "Name for the blueprint assignment")]
    [ValidateLength(1, 90)]
    [string]$AssignmentName,

    [Parameter(HelpMessage = "Azure region for the blueprint assignment")]
    [ValidateNotNullOrEmpty()]
    [string]$Location = "East US",

    [Parameter(HelpMessage = "Blueprint parameters as hashtable or JSON file path")]
    [object]$Parameters,

    [Parameter(HelpMessage = "Resource group name mappings")]
    [hashtable]$ResourceGroupNames,

    [Parameter(HelpMessage = "Use system-assigned managed identity")]
    [switch]$SystemAssignedIdentity,

    [Parameter(HelpMessage = "User-assigned managed identity resource ID")]
    [ValidatePattern('^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[^/]+$')]
    [string]$UserAssignedIdentityId,

    [Parameter(HelpMessage = "Wait for blueprint assignment completion")]
    [switch]$Wait,

    [Parameter(HelpMessage = "Timeout in minutes for blueprint assignment")]
    [ValidateRange(1, 480)]
    [int]$TimeoutMinutes = 30,

    [Parameter(HelpMessage = "Show what would be deployed without applying")]
    [switch]$WhatIf,

    [Parameter(HelpMessage = "Force application even with warnings")]
    [switch]$Force,

    [Parameter(HelpMessage = "Path for detailed logging")]
    [ValidateScript({ Test-Path (Split-Path $_ -Parent) })]
    [string]$LogPath
)

#region Functions

# Initialize logging
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if (-not $LogPath) {
    $LogPath = Join-Path $env:TEMP "apply-blueprint_$timestamp.log"
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

function Get-BlueprintDefinition {
    param(
        [string]$Name,
        [string]$Version,
        [string]$SubscriptionId
    )

    try {
        $scope = if ($SubscriptionId) { "/subscriptions/$SubscriptionId" } else { $null }

        if ($Version) {
            $blueprint = Get-AzBlueprint -Name $Name -SubscriptionId $SubscriptionId -Version $Version
        }
        else {
            # Get latest published version
            $blueprints = Get-AzBlueprint -Name $Name -SubscriptionId $SubscriptionId |
                Where-Object { $_.Status -eq 'Published' } |
                Sort-Object Version -Descending

            if ($blueprints) {
                $blueprint = $blueprints[0]
                Write-Log "Using latest published version: $($blueprint.Version)"
            }
            else {
                throw "No published versions found for blueprint '$Name'"
            }
        }

        return $blueprint
    }
    catch {
        Write-Log "Failed to get blueprint definition: $($_.Exception.Message)" -Level Error
        throw
    }
}

function ConvertTo-BlueprintParameters {
    param([object]$InputParameters)

    if (-not $InputParameters) {
        return @{}
    }

    if ($InputParameters -is [string] -and (Test-Path $InputParameters)) {
        try {
            $paramContent = Get-Content $InputParameters -Raw | ConvertFrom-Json
            $paramHash = @{}
            $paramContent.PSObject.Properties | ForEach-Object {
                $paramHash[$_.Name] = @{ value = $_.Value }
            }
            return $paramHash
        }
        catch {
            Write-Log "Failed to parse parameter file '$InputParameters': $($_.Exception.Message)" -Level Error
            throw
        }
    }
    elseif ($InputParameters -is [hashtable]) {
        $paramHash = @{}
        $InputParameters.GetEnumerator() | ForEach-Object {
            $paramHash[$_.Key] = @{ value = $_.Value }
        }
        return $paramHash
    }
    else {
        throw "Parameters must be a hashtable or path to a JSON file"
    }
}

function New-BlueprintAssignment {
    param(
        [object]$Blueprint,
        [string]$Name,
        [string]$SubscriptionId,
        [string]$Location,
        [hashtable]$Parameters,
        [hashtable]$ResourceGroups,
        [string]$IdentityType,
        [string]$UserAssignedIdentityId
    )

    try {
        $assignmentParams = @{
            Blueprint = $Blueprint
            Name = $Name
            SubscriptionId = $SubscriptionId
            Location = $Location
        }

        if ($Parameters -and $Parameters.Count -gt 0) {
            $assignmentParams.Parameter = $Parameters
        }

        if ($ResourceGroups -and $ResourceGroups.Count -gt 0) {
            $assignmentParams.ResourceGroupParameter = $ResourceGroups
        }

        # Configure identity
        if ($UserAssignedIdentityId) {
            $assignmentParams.UserAssignedIdentity = @{ $UserAssignedIdentityId = @{} }
        }
        else {
            $assignmentParams.SystemAssignedIdentity = $true
        }

        Write-Log "Creating blueprint assignment '$Name'..."
        $assignment = New-AzBlueprintAssignment @assignmentParams

        Write-Log "Blueprint assignment created successfully. Assignment ID: $($assignment.Id)"
        return $assignment
    }
    catch {
        Write-Log "Failed to create blueprint assignment: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Wait-ForBlueprintAssignment {
    param(
        [string]$AssignmentName,
        [string]$SubscriptionId,
        [int]$TimeoutMinutes
    )

    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $lastStatus = ""

    Write-Log "Waiting for blueprint assignment to complete (timeout: $TimeoutMinutes minutes)..."

    do {
        try {
            $assignment = Get-AzBlueprintAssignment -Name $AssignmentName -SubscriptionId $SubscriptionId
            $currentStatus = $assignment.ProvisioningState

            if ($currentStatus -ne $lastStatus) {
                Write-Log "Assignment status: $currentStatus"
                $lastStatus = $currentStatus
            }

            if ($currentStatus -eq 'Succeeded') {
                Write-Log "Blueprint assignment completed successfully!"
                return $assignment
            }
            elseif ($currentStatus -eq 'Failed') {
                Write-Log "Blueprint assignment failed!" -Level Error
                throw "Blueprint assignment failed"
            }

            Start-Sleep -Seconds 30
        }
        catch {
            Write-Log "Error checking assignment status: $($_.Exception.Message)" -Level Warning
            Start-Sleep -Seconds 30
        }
    } while ((Get-Date) -lt $timeout)

    Write-Log "Blueprint assignment timed out after $TimeoutMinutes minutes" -Level Warning
    return $null
}

# Main execution
try {
    Write-Log "Starting blueprint application process..."
    Write-Log "Blueprint: $BlueprintName"

    # Test Azure connection
    if (-not (Test-AzureConnection)) {
        throw "Azure connection required. Please run Connect-AzAccount first."
    }

    # Set subscription context if provided
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-Log "Set subscription context: $SubscriptionId"
    }
    else {
        $context = Get-AzContext
        $SubscriptionId = $context.Subscription.Id
        Write-Log "Using current subscription: $SubscriptionId"
    }

    # Generate assignment name if not provided
    if (-not $AssignmentName) {
        $AssignmentName = "$BlueprintName-assignment-$timestamp"
        Write-Log "Generated assignment name: $AssignmentName"
    }

    # Get blueprint definition
    Write-Log "Retrieving blueprint definition..."
    $blueprint = Get-BlueprintDefinition -Name $BlueprintName -Version $BlueprintVersion -SubscriptionId $SubscriptionId
    Write-Log "Found blueprint: $($blueprint.DisplayName) (Version: $($blueprint.Version))"

    # Process parameters
    $blueprintParameters = ConvertTo-BlueprintParameters -InputParameters $Parameters
    if ($blueprintParameters.Count -gt 0) {
        Write-Log "Processed $($blueprintParameters.Count) blueprint parameters"
    }

    # Configure resource group mappings
    $rgMappings = @{}
    if ($ResourceGroupNames) {
        $rgMappings = $ResourceGroupNames
        Write-Log "Configured $($rgMappings.Count) resource group mappings"
    }

    # Validate identity configuration
    if ($SystemAssignedIdentity -and $UserAssignedIdentityId) {
        throw "Cannot specify both SystemAssignedIdentity and UserAssignedIdentityId"
    }

    $identityType = if ($UserAssignedIdentityId) { "UserAssigned" } else { "SystemAssigned" }
    Write-Log "Using $identityType managed identity"

    # WhatIf processing
    if ($WhatIf) {
        Write-Log "WhatIf mode: Would create blueprint assignment with the following configuration:" -Level Warning
        Write-Log "  Assignment Name: $AssignmentName"
        Write-Log "  Blueprint: $($blueprint.DisplayName) v$($blueprint.Version)"
        Write-Log "  Location: $Location"
        Write-Log "  Identity Type: $identityType"
        Write-Log "  Parameters: $($blueprintParameters.Count) parameters"
        Write-Log "  Resource Groups: $($rgMappings.Count) mappings"
        return
    }

    # Create blueprint assignment
    $assignment = New-BlueprintAssignment -Blueprint $blueprint -Name $AssignmentName -SubscriptionId $SubscriptionId -Location $Location -Parameters $blueprintParameters -ResourceGroups $rgMappings -IdentityType $identityType -UserAssignedIdentityId $UserAssignedIdentityId

    # Wait for completion if requested
    if ($Wait) {
        $finalAssignment = Wait-ForBlueprintAssignment -AssignmentName $AssignmentName -SubscriptionId $SubscriptionId -TimeoutMinutes $TimeoutMinutes
        if ($finalAssignment) {
            Write-Log "Blueprint application completed successfully!"
            Write-Log "Final status: $($finalAssignment.ProvisioningState)"
        }
        else {
            Write-Log "Blueprint application may still be in progress. Check Azure portal for status." -Level Warning
        }
    }
    else {
        Write-Log "Blueprint assignment initiated. Use -Wait parameter to monitor completion."
    }

    Write-Log "Blueprint application process completed. Assignment ID: $($assignment.Id)"

    # Return assignment object
    return $assignment
}
catch {
    $errorMessage = "Blueprint application failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level Error
    throw $_
}
finally {
    Write-Log "Log file saved to: $LogPath"
}

#endregion\n