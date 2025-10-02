#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create Resource Group Assignment

.DESCRIPTION
    Azure automation script to create a resource group and assign a service principal owner access to that group.
    This is useful for setting up permissions for service principals that need to manage resources within specific resource groups.

.PARAMETER ResourceGroupName
    Name of the resource group to create or use

.PARAMETER Location
    Azure location where the resource group will be created

.PARAMETER AppId
    Application ID of the service principal to assign owner role

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
    Use this script to create a resource group and assign a principal access to that group
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$AppId
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Starting resource group assignment process..."
    Write-Output "Resource Group: $ResourceGroupName"
    Write-Output "Location: $Location"
    Write-Output "Application ID: $AppId"

    # Check if resource group exists, create if it doesn't
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
    if ($null -eq $rg) {
        Write-Output "Resource group not found. Creating resource group: $ResourceGroupName"
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
        Write-Output "Resource group created successfully"

        # Wait for resource group to be fully provisioned
        Start-Sleep -Seconds 5
    }
    else {
        Write-Output "Resource group already exists: $ResourceGroupName"
    }

    # Get the service principal
    Write-Output "Getting service principal for App ID: $AppId"
    $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $AppId

    if ($null -eq $servicePrincipal) {
        throw "Service principal with Application ID '$AppId' not found"
    }

    Write-Output "Service principal found: $($servicePrincipal.DisplayName)"

    # Check if role assignment already exists
    $existingAssignment = Get-AzRoleAssignment `
        -ObjectId $servicePrincipal.Id `
        -RoleDefinitionName "Owner" `
        -Scope $rg.ResourceId `
        -ErrorAction SilentlyContinue

    if ($existingAssignment) {
        Write-Output "Role assignment already exists for this service principal"
        $ra = $existingAssignment
    }
    else {
        # Create role assignment parameters
        Write-Output "Creating role assignment for service principal..."
        $params = @{
            ObjectId           = $servicePrincipal.Id
            RoleDefinitionName = "Owner"
            Scope              = $rg.ResourceId
        }

        # Create the role assignment
        $ra = New-AzRoleAssignment @params
        Write-Output "Role assignment created successfully"
    }

    # Display role assignment details
    Write-Output "`nRole Assignment Details:"
    Write-Output "========================"
    Write-Output "Role Assignment ID: $($ra.RoleAssignmentId)"
    Write-Output "Principal ID: $($ra.ObjectId)"
    Write-Output "Principal Type: $($ra.ObjectType)"
    Write-Output "Role: $($ra.RoleDefinitionName)"
    Write-Output "Scope: $($ra.Scope)"

    # Wait for role assignment to propagate (if Wait-ForResource.ps1 exists)
    $waitScriptPath = Join-Path $PSScriptRoot "Wait-ForResource.ps1"
    if (Test-Path $waitScriptPath) {
        Write-Output "`nWaiting for role assignment to propagate..."
        & $waitScriptPath -resourceId $ra.RoleAssignmentId -apiVersion "2022-04-01"
        Write-Output "Role assignment is ready"
    }
    else {
        Write-Output "`nWaiting 10 seconds for role assignment to propagate..."
        Start-Sleep -Seconds 10
    }

    Write-Output "`nResource group assignment completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}