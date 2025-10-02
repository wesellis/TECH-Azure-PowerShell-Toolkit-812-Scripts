#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    apply blueprint
.DESCRIPTION
    apply blueprint operation
    Author: Wes Ellis (wes@wesellis.com)

    Applies an Azure Blueprint to a subscription with

    This script applies an Azure Blueprint to a specified subscription, providing
    configuration options, validation, and monitoring capabilities. It supports both published
    and draft blueprints with flexible parameter handling and detailed logging.
.parameter BlueprintName
    The name of the Azure Blueprint to apply.
.parameter SubscriptionId
    The Azure subscription ID where the blueprint will be applied.
    If not provided, uses the current subscription context.
.parameter BlueprintVersion
    The version of the blueprint to apply. If not specified, uses the latest published version.
.parameter AssignmentName
    Name for the blueprint assignment. If not provided, generates one based on blueprint name and timestamp.
.parameter Location
    Azure region for the blueprint assignment. Defaults to 'East US'.
.parameter Parameters
    Hashtable of parameters to pass to the blueprint. Can also be a path to a JSON file.
.parameter ResourceGroupNames
    Hashtable mapping resource group placeholder names to actual resource group names.
.parameter SystemAssignedIdentity
    Use system-assigned managed identity for the blueprint assignment.
.parameter UserAssignedIdentityId
    Resource ID of a user-assigned managed identity to use for the blueprint assignment.
.parameter Wait
    Wait for the blueprint assignment to complete before returning.
.parameter TimeoutMinutes
    Maximum time to wait for blueprint assignment completion (default: 30 minutes).
.parameter WhatIf
    Show what would be deployed without actually applying the blueprint.
.parameter Force
    Force the blueprint application even if there are validation warnings.
.parameter LogPath
    Path to store detailed logs. If not provided, logs to default location.

    .\apply-blueprint.ps1 -BlueprintName "MyBlueprint" -SubscriptionId "12345678-1234-1234-1234-123456789012"

    .\apply-blueprint.ps1 -BlueprintName "MyBlueprint" -Parameters @{location="westus2"; environment="prod"} -Wait

    .\apply-blueprint.ps1 -BlueprintName "MyBlueprint" -Parameters "C:\params.json" -SystemAssignedIdentity -WhatIf

#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter(Mandatory = $true, HelpMessage = "Name of the Azure Blueprint to apply")]
    [ValidateNotNullOrEmpty()]
    [string]$BlueprintName,

    [parameter(HelpMessage = "Azure subscription ID")]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId,

    [parameter(HelpMessage = "Blueprint version to apply")]
    [ValidateNotNullOrEmpty()]
    [string]$BlueprintVersion,

    [parameter(HelpMessage = "Name for the blueprint assignment")]
    [ValidateLength(1, 90)]
    [string]$AssignmentName,

    [parameter(HelpMessage = "Azure region for the blueprint assignment")]
    [ValidateNotNullOrEmpty()]
    [string]$Location = "East US",

    [parameter(HelpMessage = "Blueprint parameters as hashtable or JSON file path")]
    [object]$Parameters,

    [parameter(HelpMessage = "Resource group name mappings")]
    [hashtable]$ResourceGroupNames,

    [parameter(HelpMessage = "Use system-assigned managed identity")]
    [switch]$SystemAssignedIdentity,

    [parameter(HelpMessage = "User-assigned managed identity resource ID")]
    [ValidatePattern('^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[^/]+$')]
    [string]$UserAssignedIdentityId,

    [parameter(HelpMessage = "Wait for blueprint assignment completion")]
    [switch]$Wait,

    [parameter(HelpMessage = "Timeout in minutes for blueprint assignment")]
    [ValidateRange(1, 480)]
    [int]$TimeoutMinutes = 30,

    [parameter(HelpMessage = "Show what would be deployed without applying")]
    [switch]$WhatIf,

    [parameter(HelpMessage = "Force application even with warnings")]
    [switch]$Force,

    [parameter(HelpMessage = "Path for detailed logging")]
    [ValidateScript({ Test-Path (Split-Path $_ -Parent) })]
    [string]$LogPath
)
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if (-not $LogPath) {
    [string]$LogPath = Join-Path $env:TEMP "apply-blueprint_$timestamp.log"
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    [string]$LogEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogEntry

    switch ($Level) {
        'Error' { write-Error $Message }
        'Warning' { write-Warning $Message }
        'Debug' { write-Debug $Message }
        default { Write-Output $Message }
    }
}

function Test-AzureConnection {
    try {
    $context = Get-AzContext
        if (-not $context) {
            throw "Not connected to Azure"
        }
        write-Log "Connected to Azure as $($context.Account.Id)"
        return $true
    }
    catch {
        write-Log "Azure connection test failed: $($_.Exception.Message)" -Level Error
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
    [string]$scope = if ($SubscriptionId) { "/subscriptions/$SubscriptionId" } else { $null }

        if ($Version) {
    $blueprint = Get-AzBlueprint -Name $Name -SubscriptionId $SubscriptionId -Version $Version
        }
        else {
    $blueprints = Get-AzBlueprint -Name $Name -SubscriptionId $SubscriptionId |
                Where-Object { $_.Status -eq 'Published' } |
                Sort-Object Version -Descending

            if ($blueprints) {
    [string]$blueprint = $blueprints[0]
                write-Log "Using latest published version: $($blueprint.Version)"
            }
            else {
                throw "No published versions found for blueprint '$Name'"
            }
        }

        return $blueprint
    }
    catch {
        write-Log "Failed to get blueprint definition: $($_.Exception.Message)" -Level Error
        throw
    }
}

function ConvertTo-BlueprintParameters {
    [object]$InputParameters)

    if (-not $InputParameters) {
        return @{}
    }

    if ($InputParameters -is [string] -and (Test-Path $InputParameters)) {
        try {
    $ParamContent = Get-Content $InputParameters -Raw | ConvertFrom-Json
    $ParamHash = @{}
    [string]$ParamContent.PSObject.Properties | ForEach-Object {
    [string]$ParamHash[$_.Name] = @{ value = $_.Value }
            }
            return $ParamHash
        }
        catch {
            write-Log "Failed to parse parameter file '$InputParameters': $($_.Exception.Message)" -Level Error
            throw
        }
    }
    elseif ($InputParameters -is [hashtable]) {
    $ParamHash = @{}
    [string]$InputParameters.GetEnumerator() | ForEach-Object {
    [string]$ParamHash[$_.Key] = @{ value = $_.Value }
        }
        return $ParamHash
    }
    else {
        throw "Parameters must be a hashtable or path to a JSON file"
    }
}

function New-BlueprintAssignment {
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
    $AssignmentParams = @{
            Blueprint = $Blueprint
            Name = $Name
            SubscriptionId = $SubscriptionId
            Location = $Location
        }

        if ($Parameters -and $Parameters.Count -gt 0) {
    [string]$AssignmentParams.parameter = $Parameters
        }

        if ($ResourceGroups -and $ResourceGroups.Count -gt 0) {
    [string]$AssignmentParams.ResourceGroupParameter = $ResourceGroups
        }

        if ($UserAssignedIdentityId) {
    [string]$AssignmentParams.UserAssignedIdentity = @{ $UserAssignedIdentityId = @{} }
        }
        else {
    [string]$AssignmentParams.SystemAssignedIdentity = $true
        }

        write-Log "Creating blueprint assignment '$Name'..."
    [string]$assignment = New-AzBlueprintAssignment @assignmentParams

        write-Log "Blueprint assignment created successfully. Assignment ID: $($assignment.Id)"
        return $assignment
    }
    catch {
        write-Log "Failed to create blueprint assignment: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Wait-ForBlueprintAssignment {
    [string]$AssignmentName,
        [string]$SubscriptionId,
        [int]$TimeoutMinutes
    )
    [string]$timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    [string]$LastStatus = ""

    write-Log "Waiting for blueprint assignment to complete (timeout: $TimeoutMinutes minutes)..."

    do {
        try {
    $assignment = Get-AzBlueprintAssignment -Name $AssignmentName -SubscriptionId $SubscriptionId
    [string]$CurrentStatus = $assignment.ProvisioningState

            if ($CurrentStatus -ne $LastStatus) {
                write-Log "Assignment status: $CurrentStatus"
    [string]$LastStatus = $CurrentStatus
            }

            if ($CurrentStatus -eq 'Succeeded') {
                write-Log "Blueprint assignment completed successfully!"
                return $assignment
            }
            elseif ($CurrentStatus -eq 'Failed') {
                write-Log "Blueprint assignment failed!" -Level Error
                throw "Blueprint assignment failed"
            }

            Start-Sleep -Seconds 30
        }
        catch {
            write-Log "Error checking assignment status: $($_.Exception.Message)" -Level Warning
            Start-Sleep -Seconds 30
        }
    } while ((Get-Date) -lt $timeout)

    write-Log "Blueprint assignment timed out after $TimeoutMinutes minutes" -Level Warning
    return $null
}

try {
    write-Log "Starting blueprint application process..."
    write-Log "Blueprint: $BlueprintName"

    if (-not (Test-AzureConnection)) {
        throw "Azure connection required. Please run Connect-AzAccount first."
    }

    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        write-Log "Set subscription context: $SubscriptionId"
    }
    else {
    $context = Get-AzContext
    [string]$SubscriptionId = $context.Subscription.Id
        write-Log "Using current subscription: $SubscriptionId"
    }

    if (-not $AssignmentName) {
    [string]$AssignmentName = "$BlueprintName-assignment-$timestamp"
        write-Log "Generated assignment name: $AssignmentName"
    }

    write-Log "Retrieving blueprint definition..."
    $blueprint = Get-BlueprintDefinition -Name $BlueprintName -Version $BlueprintVersion -SubscriptionId $SubscriptionId
    write-Log "Found blueprint: $($blueprint.DisplayName) (Version: $($blueprint.Version))"
    [string]$BlueprintParameters = ConvertTo-BlueprintParameters -InputParameters $Parameters
    if ($BlueprintParameters.Count -gt 0) {
        write-Log "Processed $($BlueprintParameters.Count) blueprint parameters"
    }
    $RgMappings = @{}
    if ($ResourceGroupNames) {
    [string]$RgMappings = $ResourceGroupNames
        write-Log "Configured $($RgMappings.Count) resource group mappings"
    }

    if ($SystemAssignedIdentity -and $UserAssignedIdentityId) {
        throw "Cannot specify both SystemAssignedIdentity and UserAssignedIdentityId"
    }
    [string]$IdentityType = if ($UserAssignedIdentityId) { "UserAssigned" } else { "SystemAssigned" }
    write-Log "Using $IdentityType managed identity"

    if ($WhatIf) {
        write-Log "WhatIf mode: Would create blueprint assignment with the following configuration:" -Level Warning
        write-Log "  Assignment Name: $AssignmentName"
        write-Log "  Blueprint: $($blueprint.DisplayName) v$($blueprint.Version)"
        write-Log "  Location: $Location"
        write-Log "  Identity Type: $IdentityType"
        write-Log "  Parameters: $($BlueprintParameters.Count) parameters"
        write-Log "  Resource Groups: $($RgMappings.Count) mappings"
        return
    }
    [string]$assignment = New-BlueprintAssignment -Blueprint $blueprint -Name $AssignmentName -SubscriptionId $SubscriptionId -Location $Location -Parameters $BlueprintParameters -ResourceGroups $RgMappings -IdentityType $IdentityType -UserAssignedIdentityId $UserAssignedIdentityId

    if ($Wait) {
    [string]$FinalAssignment = Wait-ForBlueprintAssignment -AssignmentName $AssignmentName -SubscriptionId $SubscriptionId -TimeoutMinutes $TimeoutMinutes
        if ($FinalAssignment) {
            write-Log "Blueprint application completed successfully!"
            write-Log "Final status: $($FinalAssignment.ProvisioningState)"
        }
        else {
            write-Log "Blueprint application may still be in progress. Check Azure portal for status." -Level Warning
        }
    }
    else {
        write-Log "Blueprint assignment initiated. Use -Wait parameter to monitor completion."
    }

    write-Log "Blueprint application process completed. Assignment ID: $($assignment.Id)"

    return $assignment
}
catch {
    [string]$ErrorMessage = "Blueprint application failed: $($_.Exception.Message)"
    write-Log $ErrorMessage -Level Error
    throw $_
}
finally {
    write-Log "Log file saved to: $LogPath"}
